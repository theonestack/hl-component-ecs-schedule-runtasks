CfhighlanderTemplate do
   
    Parameters do
      ComponentParam 'EnvironmentName', 'dev', isGlobal: true
      ComponentParam 'EnvironmentType', 'development', isGlobal: true
  
      ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
      ComponentParam 'SubnetIds', type: 'CommaDelimitedList'
  
      ComponentParam 'EcsCluster'
    end

    run_tasks.each do |task_name, task|
      runtask_config = {}
      runtask_config.merge!(defaults)
      runtask_config.merge!(task)
      Component template: 'ecs-runtask@0.2.0', name: task_name, render: Inline, config: runtask_config do
        parameter name: 'VPCId', value: Ref('VPCId')
        parameter name: 'SubnetIds', value: Ref('SubnetIds')
        parameter name: 'EcsCluster', value: Ref('EcsCluster')
      end
    end

  end