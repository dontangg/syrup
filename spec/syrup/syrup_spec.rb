require "spec_helper"

describe Syrup do
  it "lists all institutions" do
    institution_list = Syrup.institutions
    
    institution_list.size.should == 1
    
    institution_list.should include(Institutions::ZionsBank)
    
    institution_list.each do |institution|
      institution.should respond_to(:name)
      institution.should respond_to(:id)
    end
  end
  
  it "creates a Zions Bank institution" do
    Syrup.setup_institution(:zions_bank).class.should == Syrup::Institutions::ZionsBank
  end
end