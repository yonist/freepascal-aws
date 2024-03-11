{
    AWS
    Copyright (c) 2013-2018 Marcos Douglas B. Santos

    See the file LICENSE.txt, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit aws_s3;

{$i aws.inc}

interface

uses
  //rtl
  classes,
  sysutils,
  //synapse
  synautil,
  //aws
  aws_base,
  aws_client;

const
  AWS_S3_URL = 'amazonaws.com';

type
  ES3Error = class(Exception);

  IS3Service = interface;
  IS3Bucket = interface;

  IS3Object = interface(IInterface)
  ['{FF865D65-97EE-46BC-A1A6-9D9FFE6310A4}']
    function Bucket: IS3Bucket;
    function Name: string;
    function Stream: IAWSStream;
  end;

  IS3Objects = interface(IInterface)
  ['{0CDE7D8E-BA30-4FD4-8FC0-F8291131652E}']
    function Get(const ObjectName: string; const SubResources: string): IS3Object;
    procedure Delete(const ObjectName: string);
    function Put(const ObjectName, ContentType: string; Stream: IAWSStream; const SubResources: string): IS3Object;
    function Put(const ObjectName, ContentType, AFileName, SubResources: string): IS3Object;
    function Put(const ObjectName, SubResources: string): IS3Object;
    function Options(const ObjectName: string): IS3Object;
  end;

  IS3Bucket = interface(IInterface)
  ['{7E7FA31D-7F54-4BE0-8587-3A72E7D24164}']
    function Name: string;
    function IsTruncated: Boolean;
    function MaxKeys: Integer;
    function Region: string;
    function Objects: IS3Objects;
    function ObjectsV2(AContinuationToken: string; AMaxKeys: integer): IS3Objects;
  end;

  { IS3Buckets }

  IS3Buckets = interface(IInterface)
  ['{8F994521-57A1-4FA6-9F9F-3931E834EFE2}']
    function Check(const BucketName: string): Boolean;
    function Get(const BucketName, SubResources, Query: string): IS3Bucket;
    procedure Delete(const BucketName, SubResources: string);
    function Put(const BucketName, SubResources: string): IS3Bucket;
    { TODO : Return a Bucket list }
    function All: IAWSResponse;

    function GetS3Service:IS3Service;
    procedure SetS3Service(AValue: IS3Service);
    property S3Service: IS3Service read GetS3Service write SetS3Service;
  end;

  IS3Service = interface(IInterface)
  ['{B192DB11-4080-477A-80D4-41698832F492}']
    function Online: Boolean;
    function Buckets: IS3Buckets;
    function Region: string;
  end;

  TS3Object = class sealed(TInterfacedObject, IS3Object)
  private
    FBucket: IS3Bucket;
    FName: string;
    FStream: IAWSStream;
  public
    constructor Create(Bucket: IS3Bucket; const AName: string; Stream: IAWSStream);
    class function New(Bucket: IS3Bucket; const AName: string; Stream: IAWSStream): IS3Object;
    function Bucket: IS3Bucket;
    function Name: string;
    function Stream: IAWSStream;
  end;

  { TS3Objects }

  TS3Objects = class sealed(TInterfacedObject, IS3Objects)
  private
    FClient: IAWSClient;
    FBucket: IS3Bucket;
  public
    constructor Create(Client: IAWSClient; Bucket: IS3Bucket);
    class function New(Client: IAWSClient; Bucket: IS3Bucket): IS3Objects;
    function Get(const ObjectName: string; const SubResources: string): IS3Object;
    procedure Delete(const ObjectName: string);
    function Put(const ObjectName, ContentType: string; Stream: IAWSStream; const SubResources: string): IS3Object;
    function Put(const ObjectName, ContentType, AFileName, SubResources: string): IS3Object;
    function Put(const ObjectName, SubResources: string): IS3Object;
    function Options(const ObjectName: string): IS3Object;
  end;

  TS3Service = class;

  { TS3Bucket }

  TS3Bucket = class sealed(TInterfacedObject, IS3Bucket)
  private
    FClient: IAWSClient;
    FName: string;
    FIsTruncated: Boolean;
    FMaxKeys: integer;
    FRegion: string;
  public
    constructor Create(Client: IAWSClient; Region: string; const BucketName: string);
    class function New(Client: IAWSClient; Region: string; const BucketName: string): IS3Bucket;
    function Name: string;
    function IsTruncated: Boolean;
    function MaxKeys: Integer;
    function Region: string;
    function Objects: IS3Objects;
    function ObjectsV2(AContinuationToken: string; AMaxKeys: integer): IS3Objects;
  end;

  { TS3Buckets }

  TS3Buckets = class sealed(TInterfacedObject, IS3Buckets)
  private
    FClient: IAWSClient;
    FS3Service: IS3Service;
  public
    constructor Create(Client: IAWSClient);
    class function New(Client: IAWSClient): IS3Buckets;
    function Check(const BucketName: string): Boolean;
    function Get(const BucketName, SubResources, Query: string): IS3Bucket;
    procedure Delete(const BucketName, SubResources: string);
    function Put(const BucketName, SubResources: string): IS3Bucket;
    function All: IAWSResponse;

    function GetS3Service:IS3Service;
    procedure SetS3Service(AValue: IS3Service);
    property S3Service: IS3Service read GetS3Service write SetS3Service;
  end;

  { TS3Service }

  TS3Service = class sealed(TInterfacedObject, IS3Service)
  private
    FClient: IAWSClient;
    FRegion: string;
  public
    constructor Create(Client: IAWSClient; Region: string);
    class function New(Client: IAWSClient; Region: string): IS3Service;
    function Online: Boolean;
    function Buckets: IS3Buckets;
    function Region: string;
    class function ServiceName: string;
  end;

implementation

{ TS3Object }

constructor TS3Object.Create(Bucket: IS3Bucket; const AName: string;
  Stream: IAWSStream);
begin
  inherited Create;
  FBucket := Bucket;
  FName := AName;
  FStream := Stream;
end;

class function TS3Object.New(Bucket: IS3Bucket; const AName: string;
  Stream: IAWSStream): IS3Object;
begin
  Result := Create(Bucket, AName, Stream);
end;

function TS3Object.Bucket: IS3Bucket;
begin
  Result := FBucket;
end;

function TS3Object.Name: string;
begin
  Result := FName;
end;

function TS3Object.Stream: IAWSStream;
begin
  Result := FStream;
end;

{ TS3Objects }

constructor TS3Objects.Create(Client: IAWSClient; Bucket: IS3Bucket);
begin
  inherited Create;
  FClient := Client;
  FBucket := Bucket;
end;

class function TS3Objects.New(Client: IAWSClient; Bucket: IS3Bucket): IS3Objects;
begin
  Result := Create(Client, Bucket);
end;

function TS3Objects.Get(const ObjectName: string; const SubResources: string): IS3Object;
begin
  with FClient.Send(
    TAWSRequest.New(
      'GET', FBucket.Name, TS3Service.ServiceName + '.' + FBucket.Region + '.' + AWS_S3_URL,
      '/' + ObjectName, '/' + FBucket.Name + '/' + ObjectName + SubResources
    )
  ) do
  begin
    if 200 <> Code then
      raise ES3Error.CreateFmt('Get error: %d', [Code]);
    Result := TS3Object.New(FBucket, ObjectName, Stream);
  end;
end;

procedure TS3Objects.Delete(const ObjectName: string);
begin
  with FClient.Send(
    TAWSRequest.New(
      'DELETE', FBucket.Name, AWS_S3_URL, '/' + ObjectName, '/' + FBucket.Name + '/' + ObjectName
    )
  ) do
  begin
    if 204 <> Code then
      raise ES3Error.CreateFmt('Delete error: %d', [Code]);
  end;
end;

function TS3Objects.Put(const ObjectName, ContentType: string;
  Stream: IAWSStream; const SubResources: string): IS3Object;
begin
      //  'GET', BucketName, TS3Service.ServiceName + '.' + AWS_S3_URL,
      //'', SubResources, Query, '', '', '', '/' + BucketName + '/' + SubResources
  with FClient.Send(
    TAWSRequest.New(
      'PUT', FBucket.Name, TS3Service.ServiceName + '.' + AWS_S3_URL, '', SubResources, ContentType, '', '',
      '/' + FBucket.Name + '/' + ObjectName, Stream
    )
  ) do
  begin
    if 200 <> Code then
      raise ES3Error.CreateFmt('Put error: %d', [Code]);
    Result := TS3Object.New(FBucket, ObjectName, Stream);
  end;
end;

function TS3Objects.Put(const ObjectName, ContentType, AFileName,
  SubResources: string): IS3Object;
var
  Buf: TFileStream;
begin
  writeln('AFileName ', AFileName);
  Buf := TFileStream.Create(AFileName, fmOpenRead);
  try
    Result := Put(ObjectName, ContentType, TAWSStream.New(Buf), SubResources);
  finally
    Buf.Free;
  end;
end;

function TS3Objects.Put(const ObjectName, SubResources: string): IS3Object;
var
  Buf: TMemoryStream;
begin
  Buf := TMemoryStream.Create;
  try
    // hack Synapse to add Content-Length
    Buf.WriteBuffer('', 1);
    Result := Put(ObjectName, '', TAWSStream.New(Buf), SubResources);
  finally
    Buf.Free;
  end;
end;

function TS3Objects.Options(const ObjectName: string): IS3Object;
begin
  { TODO : Not working properly yet. }
  with FClient.Send(
    TAWSRequest.New(
      'OPTIONS', FBucket.Name, AWS_S3_URL, '/' + ObjectName, '/' + FBucket.Name + '/' + ObjectName
    )
  ) do
  begin
    if 200 <> Code then
      raise ES3Error.CreateFmt('Get error: %d', [Code]);
    Result := TS3Object.New(FBucket, ObjectName, Stream);
  end;
end;

{ TS3Bucket }

constructor TS3Bucket.Create(Client: IAWSClient; Region: string;
  const BucketName: string);
begin
  inherited Create;
  FClient := Client;
  FName := BucketName;
  FRegion:= Region;
end;

class function TS3Bucket.New(Client: IAWSClient; Region: string;
  const BucketName: string): IS3Bucket;
begin
  Result := Create(Client, Region ,BucketName);
end;

function TS3Bucket.Name: string;
begin
  Result := FName;
end;

function TS3Bucket.IsTruncated: Boolean;
begin
  Result := FIsTruncated;
end;

function TS3Bucket.MaxKeys: Integer;
begin
  Result := FMaxKeys;
end;

function TS3Bucket.Region: string;
begin
  Result := FRegion;
end;

function TS3Bucket.Objects: IS3Objects;
begin
  Result := TS3Objects.New(FClient, Self);
end;

function TS3Bucket.ObjectsV2(AContinuationToken: string; AMaxKeys: integer
  ): IS3Objects;
begin
  with FClient.Send(
    TAWSRequest.New(
      'GET', Name, TS3Service.ServiceName + '.' + FRegion + '.' + AWS_S3_URL,
      '', '', 'list-type=2&max-keys='+IntToStr(AMaxKeys), '', '', '', ''
    )
  ) do
  begin
    if 200 <> Code then
      raise ES3Error.CreateFmt('Get error: %d', [Code]);
    //Result := TS3Objects.New(FClient, Name);
  end;
end;

{ TS3Buckets }

constructor TS3Buckets.Create(Client: IAWSClient);
begin
  inherited Create;
  FClient := Client;
end;

class function TS3Buckets.New(Client: IAWSClient): IS3Buckets;
begin
  Result := Create(Client);
end;

function TS3Buckets.Check(const BucketName: string): Boolean;
begin
  Result := FClient.Send(
    TAWSRequest.New(
      'HEAD', BucketName, TS3Service.ServiceName + '.' + S3Service.Region + '.' + AWS_S3_URL,
      '', '', '', '', '', ''
    )
  ).Code = 200;
end;

function TS3Buckets.Get(const BucketName, SubResources, Query: string
  ): IS3Bucket;
begin
  with FClient.Send(
    TAWSRequest.New(
      'GET', BucketName, TS3Service.ServiceName + '.' + S3Service.Region + '.' + AWS_S3_URL,
      '', '', '', '', '', ''
    )
  ) do
  begin
    if 200 <> Code then
      raise ES3Error.CreateFmt('Get error: %d, %s', [Code, Text]);
    Result := TS3Bucket.New(FClient, S3Service.Region, BucketName);
  end;
end;

procedure TS3Buckets.Delete(const BucketName, SubResources: string);
begin
  with FClient.Send(
    TAWSRequest.New(
      'DELETE', BucketName, AWS_S3_URL, '', SubResources, '', '', '', '/' + BucketName + SubResources
    )
  ) do
  begin
    if 204 <> Code then
      raise ES3Error.CreateFmt('Delete error: %d', [Code]);
  end;
end;

function TS3Buckets.Put(const BucketName, SubResources: string): IS3Bucket;
begin
  with FClient.Send(
    TAWSRequest.New(
      'PUT', BucketName, TS3Service.ServiceName + '.' + AWS_S3_URL, 
      '', SubResources, '', '', '', '', ''
    )
  ) do
  begin
    if 200 <> Code then
      raise ES3Error.CreateFmt('Put error: %d', [Code]);
    Result := TS3Bucket.New(FClient, FS3Service.Region, BucketName);
  end;
end;

function TS3Buckets.All: IAWSResponse;
begin
  Result := FClient.Send(
    TAWSRequest.New('GET', '', AWS_S3_URL, '', '', '', '', '', '/')
  );
end;

function TS3Buckets.GetS3Service: IS3Service;
begin
  Result := FS3Service;
end;

procedure TS3Buckets.SetS3Service(AValue: IS3Service);
begin
  FS3Service := AValue;
end;

{ TS3Service }

constructor TS3Service.Create(Client: IAWSClient; Region: string);
begin
  inherited Create;
  FClient := Client;
  FRegion := Region;
end;

class function TS3Service.New(Client: IAWSClient; Region: string): IS3Service;
begin
  Result := Create(Client, Region);
end;

function TS3Service.Online: Boolean;
begin
  //Result := FClient.Send(
  //  TAWSRequest.New(
  //    'GET', '', 'pyxis.test.s3.us-east-1.amazonaws.com', '', '', '', '', '', '/'
  //  )
  //).Code = 200;
  result := true;
end;

function TS3Service.Buckets: IS3Buckets;
begin
  Result := TS3Buckets.New(FClient);
  Result.S3Service := Self;
end;

function TS3Service.Region: string;
begin
  Result := FRegion;
end;

class function TS3Service.ServiceName: string;
begin
  Result := 's3';
end;

end.
