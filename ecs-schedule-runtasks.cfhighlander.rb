CfhighlanderTemplate do

  DependsOn 'lib-iam'
   
  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'

    ComponentParam 'EcsClusterArn'

    ComponentParam 'State', 'ENABLED', allowedValues: ['ENABLED', 'DISABLED']
  end

end