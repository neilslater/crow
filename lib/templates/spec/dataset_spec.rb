require 'helpers'

describe <%= full_class_name_ruby %> do
  it "is a valid Class" do
    expect(<%= full_class_name_ruby %>).to be_a Class
  end

  describe "#new" do
    it "instantiates a <%= full_class_name_ruby %>" do
      expect( <%= full_class_name_ruby %>.new( <%= init_params.map{ '1' }.join(', ') %> ) ).to be_a <%= full_class_name_ruby %>
    end
  end
end
