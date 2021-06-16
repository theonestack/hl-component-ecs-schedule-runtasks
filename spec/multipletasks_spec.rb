require 'yaml'

describe 'should fail without a task_definition' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/multipletasks.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/multipletasks/ecs-schedule-runtasks.compiled.yaml") }

  context 'Resource Task' do
    let(:properties) { template["Resources"]["Task"]["Properties"] }

    it 'has property RequiresCompatibilities ' do
      expect(properties["RequiresCompatibilities"]).to eq(['FARGATE'])
    end

    it 'has property NetworkMode ' do
      expect(properties["NetworkMode"]).to eq('awsvpc')
    end

    it 'has property CPU ' do
      expect(properties["Cpu"]).to eq(256)
    end

    it 'has property Memory ' do
      expect(properties["Memory"]).to eq(512)
    end

  end

  context 'Resource StateMachine' do
    let(:properties) { template["Resources"]["StateMachine"]["Properties"] }

    it 'has property StateMachineName' do
      expect(properties["StateMachineName"]).to eq({"Fn::Sub"=>"${EnvironmentName}-tasks1-RunTask"})
    end

    it 'has property RoleArn' do
      expect(properties["RoleArn"]).to eq({"Fn::GetAtt" => ["StepFunctionRole", "Arn"]})
    end

    it 'has property DefinitionString' do
      expect(properties["DefinitionString"]).not_to be_nil
    end
  end

  context 'Resource Schedule' do
    let(:properties) { template["Resources"]["Schedule"]["Properties"] }

    it 'has property Name' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-tasks1-schedule"})
    end

    it 'has property Description' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"{EnvironmentName} tasks1 schedule"})
    end

    it 'has property ScheduleExpression' do
      expect(properties["ScheduleExpression"]).to eq('rate(1 hour)')
    end

    it 'has property Targets' do
      expect(properties["Targets"]).to eq([{
        "Arn"=>{"Ref"=>"StateMachine"},
        "RoleArn"=>{"Fn::GetAtt"=>["EventBridgeInvokeRole", "Arn"]}
      }])
    end

  end

  context '2nd task' do
    let(:properties) { template["Resources"]["tasks2Schedule"]["Properties"] }

    it 'has property Name' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-tasks2-schedule"})
    end

    it 'has property Description' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"{EnvironmentName} tasks2 schedule"})
    end

    it 'has property ScheduleExpression' do
      expect(properties["ScheduleExpression"]).to eq('rate(2 hour)')
    end

    it 'has property Targets' do
      expect(properties["Targets"]).to eq([{
        "Arn"=>{"Ref"=>"tasks2StateMachine"},
        "RoleArn"=>{"Fn::GetAtt"=>["tasks2EventBridgeInvokeRole", "Arn"]}
      }])
    end

  end

  
end
