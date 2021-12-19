CloudFormation do

  iam_policies = external_parameters.fetch(:scheduler_iam_policies, {})
  IAM_Role(:EventBridgeInvokeRole) do
    AssumeRolePolicyDocument ({
      Statement: [
        {
          Effect: 'Allow',
          Principal: { Service: [ 'events.amazonaws.com' ] },
          Action: [ 'sts:AssumeRole' ]
        }
      ]
    })
    Path '/'
    Policies iam_role_policies(iam_policies)
  end


  run_tasks.each do |name, task|
    schedule = task['schedule']
    task_name = name.gsub("-","").gsub("_","")
    container_overrides = {}
    container_overrides[:name] = task.has_key?('container') ? task['container'] : "#{task['task_definition']}"
    container_overrides[:command] = task['command'] if task.has_key?('command')

    env_vars = []
    if !(task['env_vars'].nil?)
      task['env_vars'].each do |name,value|
        split_value = value.to_s.split(/\${|}/)
        if split_value.include? 'environment'
          fn_join = split_value.map { |x| x == 'environment' ? [ Ref('EnvironmentName'), '.', FnFindInMap('AccountId',Ref('AWS::AccountId'),'DnsDomain') ] : x }
          env_value = FnJoin('', fn_join.flatten)
        elsif value == 'cf_version'
          env_value = cf_version
        else
          env_value = value
        end
        env_vars << { name: name, value: env_value}
      end
    end
    container_overrides.merge!({environment: env_vars }) if env_vars.any?

    container_input = {
      containerOverrides: [container_overrides]
    }

    unless schedule.nil?
      Events_Rule("#{task_name}Schedule") do
        Name FnSub("${EnvironmentName}-#{name}-schedule")
        Description FnSub("${EnvironmentName} #{name} schedule")
        ScheduleExpression schedule
        State Ref(:State)
        Targets [{
          Id: name,
          Arn: Ref(:EcsClusterArn),
          RoleArn: FnGetAtt('EventBridgeInvokeRole', 'Arn'),
          EcsParameters: {
            TaskDefinitionArn: Ref("#{task['task_definition']}"),
            TaskCount: 1,
            LaunchType: 'FARGATE',
            NetworkConfiguration: {
              AwsVpcConfiguration: {
                Subnets: FnSplit(',', Ref('SubnetIds')),
                SecurityGroups: [Ref("#{task['task_definition']}SecurityGroup")],
                AssignPublicIp: "DISABLED"
              }
            }
          },
          Input: FnSub(container_input.to_json())
        }]
      end
    end
  end
end