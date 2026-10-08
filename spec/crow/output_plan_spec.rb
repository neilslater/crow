# frozen_string_literal: true

require 'spec_helper'

describe Crow::OutputPlan, :aggregate_failures do
  it 'rejects duplicate output destinations' do
    plan = described_class.new
    plan.add('/unused', 'first')
    expect { plan.add('/unused', 'second') }.to raise_error(ArgumentError, /Duplicate/)
  end

  it 'keeps the failing template path and original exception' do
    expect { described_class.render('broken.erb', binding, '<%= missing_method %>') }
      .to raise_error(ArgumentError, /broken.erb/) { |error| expect(error.cause).to be_a(NameError) }
  end
end
