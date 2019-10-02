require 'helpers'

describe <%= full_class_name_ruby %> do
  it "is a valid Class" do
    expect(<%= full_class_name_ruby %>).to be_a Class
  end
end
