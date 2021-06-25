require 'yaml'

describe 'should fail without a task_definition' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/multipletasks.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/multipletasks/ecs-schedule-runtasks.compiled.yaml") }


  context 'Resource Schedule Task1' do
    let(:properties) { template["Resources"]["task1Schedule"]["Properties"] }

    it 'has property Name' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-task1-schedule"})
    end

    it 'has property Description' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"{EnvironmentName} task1 schedule"})
    end

    it 'has property ScheduleExpression' do
      expect(properties["ScheduleExpression"]).to eq('rate(1 hour)')
    end

    it 'has property Targets' do
      expect(properties["Targets"]).to eq([
        {"Arn"=>{"Ref"=>"EcsClusterArn"},
          "EcsParameters"=>
            {"LaunchType"=>"FARGATE",
             "NetworkConfiguration"=>
              {"AwsVpcConfiguration"=>
                {"AssignPublicIp"=>"DISABLED",
                 "SecurityGroups"=>[{"Ref"=>"task1SecurityGroup"}],
                 "Subnets"=>{"Fn::Split"=>[",", {"Ref"=>"SubnetIds"}]}}},
             "TaskCount"=>1,
             "TaskDefinitionArn"=>{"Ref"=>"task1"}},
          "Id"=>"task1-dGFzazE",
           "Input"=>
            "{\"containerOverrides\":{\"name\":\"task1\"}}",
           "RoleArn"=>{"Fn::GetAtt"=>["EventBridgeInvokeRole", "Arn"]}}
      ])
    end

  end

  context 'Resource Schedule Task2' do
    let(:properties) { template["Resources"]["task2Schedule"]["Properties"] }

    it 'has property Name' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-task2-schedule"})
    end

    it 'has property Description' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"{EnvironmentName} task2 schedule"})
    end

    it 'has property ScheduleExpression' do
      expect(properties["ScheduleExpression"]).to eq('cron(15 10 ? * 6L 2019-2022)')
    end

    it 'has property Targets' do
      expect(properties["Targets"]).to eq([
        {"Arn"=>{"Ref"=>"EcsClusterArn"},
          "EcsParameters"=>
            {"LaunchType"=>"FARGATE",
             "NetworkConfiguration"=>
              {"AwsVpcConfiguration"=>
                {"AssignPublicIp"=>"DISABLED",
                 "SecurityGroups"=>[{"Ref"=>"task2SecurityGroup"}],
                 "Subnets"=>{"Fn::Split"=>[",", {"Ref"=>"SubnetIds"}]}}},
             "TaskCount"=>1,
             "TaskDefinitionArn"=>{"Ref"=>"task2"}},
          "Id"=>"task2-dGFzazI",
           "Input"=>
            "{\"containerOverrides\":{\"name\":\"task2\",\"command\":\"[\\\"echo\\\", \\\"foo\\\", \\\"bar\\\"]\"}}",
           "RoleArn"=>{"Fn::GetAtt"=>["EventBridgeInvokeRole", "Arn"]}}
      ])
    end

  end
  
end
