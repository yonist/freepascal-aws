program s3;
{$mode objfpc}{$H+}
uses
  aws_credentials,
  aws_client,
  aws_s3;

begin
  TS3Service.New(
    TAWSClient.New(
      TAWSSignatureVersion4.New(
        TAWSCredentials.New('AKIAQBPS4Q6OCXMMXU7V', 'UDBVkwMBZxrQUy2VHe1ceWUnZLnQIX4sZqC3Z7gW', false, 'us-east-1')
      ), TS3Service.ServiceName
    )
  )
  .Buckets
  .Get('pyxis.test', '/', '');
end.

