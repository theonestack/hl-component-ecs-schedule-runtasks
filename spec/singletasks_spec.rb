require 'yaml'

describe 'should fail without a task_definition' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/singletask.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/singletask/ecs-schedule-runtasks.compiled.yaml") }

  context 'Resource Event Bridge IAM Role' do
    let(:properties) { template["Resources"]["EventBridgeInvokeRole"]["Properties"] }

    it 'has a event bridge assume role policy' do
      expect(properties["AssumeRolePolicyDocument"]).to eq({
        "Statement"=>[
          {
            "Action"=>["sts:AssumeRole"],
            "Effect"=>"Allow",
            "Principal"=>{"Service"=>["events.amazonaws.com"]
          }
        }]
      })
    end

    it 'has Policies to allow running tasks limited to a given cluster' do
      expect(properties["Policies"]).to eq([
        {"PolicyDocument"=>
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Action"=>["ecs:RunTask"],
                "Condition"=>{"ArnLike"=>{"ecs:cluster"=>[{"Ref"=>"EcsClusterArn"}]}},
                "Effect"=>"Allow",
                "Resource"=>["*"],
                "Sid"=>"ecsruntask"}]},
           "PolicyName"=>"ecs-runtask"},
          {"PolicyDocument"=>
            {"Version"=>"2012-10-17",
             "Statement"=>
              [{"Action"=>["iam:PassRole"],
                "Condition"=>
                 {"StringLike"=>{"iam:PassedToService"=>"ecs-tasks.amazonaws.com"}},
                "Effect"=>"Allow",
                "Resource"=>["*"],
                "Sid"=>"ecspassrole",}]},
           "PolicyName"=>"ecs-pass-role"}        
      ])
    end
  end

  context 'Resource Schedule' do
    let(:properties) { template["Resources"]["singletaskSchedule"]["Properties"] }

    it 'has property Name' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-singletask-schedule"})
    end

    it 'has property Description' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} singletask schedule"})
    end

    it 'has property ScheduleExpression' do
      expect(properties["ScheduleExpression"]).to eq('rate(1 hour)')
    end

    it 'has property State' do
      expect(properties["State"]).to eq("Ref"=>"State")
    end

    it 'has property Targets' do
      expect(properties["Targets"]).to eq([
        {"Arn"=>{"Ref"=>"EcsClusterArn"},
          "EcsParameters"=>
            {"LaunchType"=>"FARGATE",
            "EnableExecuteCommand"=>true,
             "NetworkConfiguration"=>
              {"AwsVpcConfiguration"=>
                {"AssignPublicIp"=>"DISABLED",
                 "SecurityGroups"=>[{"Ref"=>"mytaskSecurityGroup"}],
                 "Subnets"=>{"Fn::Split"=>[",", {"Ref"=>"SubnetIds"}]}}},
             "TaskCount"=>1,
             "TaskDefinitionArn"=>{"Ref"=>"mytask"}},
          "Id"=>"singletask",
          
          "Input"=>{"Fn::Sub"=>
            "{\"containerOverrides\":[{\"name\":\"singletask\",\"command\":[\"echo\",\"hello world\"],\"environment\":[{\"name\":\"foo\",\"value\":\"bar\"}]}]}"
          },
          "RoleArn"=>{"Fn::GetAtt"=>["EventBridgeInvokeRole", "Arn"]}}
      ])
    end

  end


  
end
