require 'helpers'

describe <%= full_class_name_ruby %> do
  it "is a valid Class" do
    expect(<%= full_class_name_ruby %>).to be_a Class
  end

  describe "#new" do
    it "instantiates a <%= full_class_name_ruby %>" do
      expect( <%= full_class_name_ruby %>.new( <%= init_params.map{ |ip| ip.min_valid.to_s }.join(', ') %> ) ).to be_a <%= full_class_name_ruby %>
    end
<% init_params.select(&:validate?).each do |iparam| -%>
<% if iparam.init.validate_min -%>

    it "raises when <%= iparam.name %> = <%= iparam.init.validate_min-1 %> (too low)" do
      expect {
        <%= full_class_name_ruby %>.new( <%= init_params.map{ |ip| iparam.name == ip.name ? iparam.init.validate_min-1 : ip.min_valid.to_s }.join(', ') %> )
      }.to raise_error ArgumentError, /<%= iparam.name %>/
    end
<% end -%>
<% if iparam.init.validate_max -%>

    it "raises when <%= iparam.name %> = <%= iparam.init.validate_max+1 %> (too high)" do
      expect {
        <%= full_class_name_ruby %>.new( <%= init_params.map{ |ip| iparam.name == ip.name ? iparam.init.validate_max+1 : ip.min_valid.to_s }.join(', ') %> )
      }.to raise_error ArgumentError, /<%= iparam.name %>/
    end
<% end -%>
<% end -%>

    describe "default attribute values" do
      subject { <%= full_class_name_ruby %>.new( <%= init_params.map{ |ip| ip.min_valid.to_s }.join(', ') %> ) }

<% testable_attributes.each do |attribute| -%>
      describe "<%= attribute.name %>" do
        it "has value of <%= attribute.test_value %>" do
          expect(subject.<%= attribute.name %>).to eql <%= attribute.test_value %>
        end
      end
<% end -%>
    end
  end
end
