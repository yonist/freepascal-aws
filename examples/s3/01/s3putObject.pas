program s3putObject;
{$mode objfpc}{$H+}
uses
  aws_credentials,
  aws_client,
  aws_s3;

var
  LSignatureV4: IAWSSignature;
begin
  LSignatureV4 := TAWSSignatureVersion4.New(
                    TAWSCredentials.New('AKIAQBPS4Q6OCXMMXU7V',
                                        'UDBVkwMBZxrQUy2VHe1ceWUnZLnQIX4sZqC3Z7gW',
                                        false,
                                        'us-east-1'));
  LSignatureV4.SetSigningType(stQuerystring);

  TS3Service.New(
    TAWSClient.New( LSignatureV4, TS3Service.ServiceName)
  )
  .Buckets
  .Get('pyxis.test', '/', '')
  .Objects
  .Put('ss.png', 'png', 'ss.png', '');
end.

