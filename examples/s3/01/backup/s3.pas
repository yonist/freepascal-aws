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
        TAWSCredentials.New('', '', false, 'us-east-1')
      ), TS3Service.ServiceName
    )
  )
  .Buckets
  .Get('pyxis.test', '/', '');
  //.Objects;
  //.Get('', '');
  //.Put('ss.png', 'png', 'ss.png', '');
end.

