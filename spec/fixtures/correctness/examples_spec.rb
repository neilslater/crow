# frozen_string_literal: true

RSpec.shared_examples 'native correctness contracts' do
  context 'with generated native behavior', :aggregate_failures do
    let(:scalar) { Contract::Scalar.new }
    let(:buffers) { Contract::Buffers.new(3) }
    let(:empty_scalar) { Contract::Scalar.allocate }
    let(:empty_buffers) { Contract::Buffers.allocate }

    it 'runs scalar-only initializers and uses the public reader name' do
      expect(scalar.value).to eq 7
      expect(scalar).not_to respond_to(:hidden)
    end

    it 'round trips nil, retains extra-key tolerance and preserves subclasses' do
      klass = Class.new(Contract::Scalar)
      result = klass.from_h(**scalar.to_h, extra: 1)
      expect(result).to be_a klass
      expect(result.to_h).to eq scalar.to_h
    end

    it 'distinguishes absent keys from nil' do
      expect { Contract::Scalar.from_h(number: 1, hidden: 0) }.to raise_error(ArgumentError, /data/)
      expect { Contract::Scalar.from_h(number: nil, hidden: 0, data: nil) }.to raise_error(TypeError)
    end

    it 'checks bounds without changing the receiver' do
      expect { scalar.value = 20 }.to raise_error(ArgumentError)
      expect(scalar.value).to eq 7
      expect { Contract::Scalar.from_h(number: 20, hidden: 0, data: nil) }.to raise_error(ArgumentError)
    end

    it 'rejects uninitialized access and copying' do
      expect { empty_scalar.value }.to raise_error(RuntimeError)
      expect { empty_scalar.to_h }.to raise_error(RuntimeError)
      expect { empty_scalar.dup }.to raise_error(RuntimeError)
    end

    it 'supports explicit initialization once' do
      empty_scalar.send(:initialize)
      expect(empty_scalar.value).to eq 7
      expect { empty_scalar.send(:initialize) }.to raise_error(RuntimeError)
    end

    it 'honors freezing for generated mutations' do
      scalar.freeze
      expect { scalar.value = 1 }.to raise_error(FrozenError)
      expect { scalar.send(:initialize) }.to raise_error(FrozenError)
      expect { scalar.send(:initialize_copy, Contract::Scalar.new) }.to raise_error(FrozenError)
    end

    it 'preserves normal frozen clone and self-copy semantics' do
      scalar.freeze
      expect(scalar.clone).to be_frozen
      expect(scalar.clone(freeze: false)).not_to be_frozen
      expect(scalar.dup).not_to be_frozen
      expect(scalar.send(:initialize_copy, scalar)).to equal scalar
    end

    it 'validates native identity before reading a layout' do
      [Object.new, buffers, Contract::Scalar.typed, Contract::Scalar.null].each do |object|
        expect { Contract::Scalar.extract(object) }.to raise_error(TypeError)
      end
      expect(Contract::Scalar.extract(Contract::Scalar.legacy)).to be true
    end

    it 'preserves same-subclass copies' do
      klass = Class.new(Contract::Scalar)
      expect(klass.new.dup).to be_a klass
    end

    it 'rejects cross-class and initialized-destination copies' do
      item = Class.new(Contract::Scalar).new
      expect { empty_scalar.send(:initialize_copy, item) }.to raise_error(TypeError)
      expect { scalar.send(:initialize_copy, buffers) }.to raise_error(TypeError)
      expect { scalar.send(:initialize_copy, Contract::Scalar.new) }.to raise_error(RuntimeError)
    end

    it 'keeps ordinary VALUE copying shallow' do
      value = []
      scalar.data = value
      expect(scalar.dup.data).to equal value
    end

    it 'restores residual buffers without pretending to serialize their contents' do
      restored = Contract::Buffers.from_h(**buffers.to_h)
      expect(restored.first).to eq [3, 3, 3]
      expect(restored.second).to eq [2.5, 2.5, 2.5]
      expect(restored.native_clone.first).to eq restored.first
    end

    it 'uses recorded extents when native code changes the count field' do
      buffers.change_count(200)
      expect(buffers.first).to eq [3, 3, 3]
      expect(buffers.dup.first).to eq [3, 3, 3]
    end

    it 'handles zero length and rejects negative counts before storage access' do
      expect(Contract::Buffers.new(0).first).to eq []
      expect { Contract::Buffers.new(-1) }.to raise_error(ArgumentError)
    end

    it 'rejects arithmetic, byte-count and NArray product overflow before allocation' do
      expect { Contract::Sizes.new((2**64) - 1, 1) }.to raise_error(RangeError)
      expect { Contract::Sizes.new(2**60, 1) }.to raise_error(RangeError)
      expect { Contract::Dimensions.new(2**32) }.to raise_error(RangeError)
      expect { Contract::Sizes.new(2, 0) }.to raise_error(RangeError)
    end

    it 'resets failed conversion state so initialization can be retried' do
      item = Contract::Buffers.allocate
      expect { item.send(:initialize, Object.new) }.to raise_error(TypeError)
      item.send(:initialize, 2)
      expect(item.first).to eq [3, 3]
    end

    def converting_value(&callback)
      Object.new.tap { |value| value.define_singleton_method(:to_int, &callback) }
    end

    it 'rejects reentrant reads during conversion' do
      item = empty_buffers
      value = converting_value { item.first }
      expect { empty_buffers.send(:initialize, value) }.to raise_error(RuntimeError)
      empty_buffers.send(:initialize, 1)
      expect(empty_buffers.first).to eq [3]
    end

    it 'rechecks freezing after user conversion callbacks' do
      item = empty_buffers
      value = converting_value { item.freeze && 2 }
      expect { empty_buffers.send(:initialize, value) }.to raise_error(FrozenError)
      expect { empty_buffers.first }.to raise_error(RuntimeError)
    end

    def with_failure(point, &block)
      baseline = Contract::Buffers.allocations
      Contract::Buffers.fail_after(point)
      expect(&block).to raise_error(NoMemoryError)
      Contract::Buffers.fail_after(-1)
      expect(Contract::Buffers.allocations).to eq baseline
    ensure
      Contract::Buffers.fail_after(-1)
    end

    [0, 1, 2].each do |point|
      it "cleans up and permits retry after allocation #{point} fails" do
        item = empty_buffers
        with_failure(point) { item.send(:initialize, 2) }
        item.send(:initialize, 1)
        expect(item.first).to eq [3]
      end
    end

    it 'cleans up native clone when a later allocation fails' do
      original = buffers
      with_failure(3) { original.native_clone }
      expect(original.first).to eq [3, 3, 3]
    end

    def expect_materialized_view(view)
      item = Contract::Array.from_h(count: 3, data: view)
      expect(item.data.to_a).to eq [10, 20, 30]
      expect(item.native_first).to eq 10
      expect_independent_storage(item, view)
    end

    def expect_independent_storage(item, view)
      expect(item.data).not_to equal view
      item.data[0] = 42
      expect(view[0]).to eq 10
    end

    it 'materializes offset and indexed NArray views' do
      expect_materialized_view(Numo::DFloat[99, 10, 20, 30][1..3])
      expect_materialized_view(Numo::DFloat[10, 99, 20, 99, 30][[0, 2, 4]])
    end

    it 'checks dtype, rank, dimensions and unavailable restoration parameters' do
      [Numo::SFloat[1, 2], Numo::DFloat[[1, 2]], Numo::DFloat[1]].each do |array|
        expect { Contract::Array.from_h(count: 2, data: array) }.to raise_error(StandardError)
      end
      expect { Contract::Unavailable.from_h(data: Numo::SFloat[1]) }.to raise_error(ArgumentError, /width/)
    end

    it 'copies NArrays independently' do
      item = Contract::Array.new(3)
      item.dup.data[0] = 9
      expect(item.native_first).to eq 4
    end

    it 'rejects changed NArray shape' do
      item = Contract::Array.new(3)
      item.data.reshape!(1, 3)
      expect { item.native_first }.to raise_error(ArgumentError)
    end

    it 'restores dependent scalars in dependency order' do
      expect(Contract::Residual.from_h(count: 5).third).to eq 7
    end

    it 'constructs maintained pointer families' do
      item = Contract::Families.new
      expect(item.ptr_ulong).to eq [0, 0]
      expect(item.ptr_float).to eq [0.0, 0.0]
    end

    it 'constructs every maintained NArray family' do
      item = Contract::Families.new
      expect(item.narray_int16.to_a).to eq [0]
      expect(item.narray_int32.to_a).to eq [0]
      expect(item.narray_double.to_a).to eq [0.0]
      expect(item.narray_float.to_a).to eq [0.0]
    end
  end
end
