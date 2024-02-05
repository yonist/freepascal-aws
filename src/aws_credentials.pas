{
    AWS
    Copyright (c) 2013-2018 Marcos Douglas B. Santos

    See the file LICENSE.txt, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit aws_credentials;

{$i aws.inc}

interface

uses
  //rtl
  sysutils,
  classes,
  dateutils,
  //synapse
  synacode,
  synautil,
  //terceiros
  SynCrypto,
  //aws
  SynCommons,
  StrUtils,
  aws_http;


type

  IAWSSignatureHMAC256 = interface(IInterface)
  ['{9158D9A2-7ABA-4126-9F63-264E947AC60A}']
    function AccessKey: string;
    function DataStamp: string;
    function RegionName: string;
    function ServiceName: string;
    function Signature: TSHA256Digest;
  end;

  { TAWSSignatureHMAC256 }

  TAWSSignatureHMAC256 = class sealed(TInterfacedObject, IAWSSignatureHMAC256)
  private
    FAccessKey: string;
    FSecretKey: string;
    FDataStamp: string;
    FRegionName: string;
    FServiceName: string;
  public
    constructor Create(const AccessKey, DataStamp, RegionName, ServiceName: string);
    constructor Create(const AccessKey, SecretKey, DataStamp, RegionName, ServiceName: string);
    class function New(const AccessKey, DataStamp, RegionName, ServiceName: string): IAWSSignatureHMAC256;
    class function New(const AccessKey, SecretKey, DataStamp, RegionName, ServiceName: string): IAWSSignatureHMAC256;
    function AccessKey: string;
    function SecretKey: string;
    function DataStamp: string;
    function RegionName: string;
    function ServiceName: string;
    function Signature: TSHA256Digest;
  end;

  IAWSCredentials = interface(IInterface)
  ['{AC6EA523-F2FF-4BD0-8C87-C27E9846FA40}']
    function AccessKeyId: string;
    function SecretKey: string;
    function UseSSL: Boolean;
    function RegionName: string;
  end;

  { IAWSSignature }

  IAWSSignature = interface
    function Credentials: IAWSCredentials;
    function Calculate(Request: IHTTPRequest): string;
    function CalculateToQuery(Request: IHTTPRequest; var Headers: string): String;
  end;

  { TAWSCredentials }

  TAWSCredentials = class sealed(TInterfacedObject, IAWSCredentials)
  private
    FAccessKeyId: string;
    FSecretKey: string;
    FSSL: Boolean;
    FRegionName: string;
  public
    constructor Create(
      const AccessKeyId, SecretKey: string;
      UseSSL: Boolean); reintroduce;
    constructor Create(
      const AccessKeyId, SecretKey: string;
      UseSSL: Boolean; RegionName: string); reintroduce;
    class function New(
      const AccessKeyId, SecretKey: string;
      UseSSL: Boolean): IAWSCredentials;
    class function New(
      const AccessKeyId, SecretKey: string;
      UseSSL: Boolean; RegionName: string): IAWSCredentials;
    function AccessKeyId: string;
    function SecretKey: string;
    function UseSSL: Boolean;
    function RegionName: string;
  end;

  { TAWSAbstractSignature }

  TAWSAbstractSignature = class abstract(TInterfacedObject, IAWSSignature)
  strict private
    FCredentials: IAWSCredentials;
  public
    constructor Create(Credentials: IAWSCredentials);
    class function New(Credentials: IAWSCredentials): IAWSSignature;
    function Credentials: IAWSCredentials;
    function Calculate(Request: IHTTPRequest): string; virtual; abstract;
    function CalculateToQuery(Request: IHTTPRequest; var Headers: string): String; virtual; abstract;
  end;

  { TAWSSignatureVersion1 }

  TAWSSignatureVersion1 = class sealed(TAWSAbstractSignature)
  public
    function Calculate(Request: IHTTPRequest): string; override;
    function CalculateToQuery(Request: IHTTPRequest; var Headers: string): String; override;
  end;

  { TAWSSignatureVersion3 }

  TAWSSignatureVersion3 = class sealed(TAWSAbstractSignature)
  public
    function Calculate(Request: IHTTPRequest): string; override;
    function CalculateToQuery(Request: IHTTPRequest; var Headers: string): String; override;
  end;

  { TStringListHelper }

  TStringListHelper = class helper for TStringList
    function Join(Separator: char): string;
  end;

  { TAWSSignatureVersion4 }

  TAWSSignatureVersion4 = class sealed(TAWSAbstractSignature)
  private
    function BuildHeader(const Header: String): String;
    procedure SignedHeaders(const Header: String; var ToSing, ToCanonical: String);
    function CreatePresignedURL(Request: IHTTPRequest): string;
    function CreateCredentialScope(date, region, service: string): string;
    function CreateSignedHeaders(Request: IHTTPRequest): String;
    function CreateCanonicalRequest(Request: IHTTPRequest; Queries, Headers: TStringList;
      Payload: string): string;
    function CreateStringToSign(Request: IHTTPRequest; CanonicalRequest,
      Time, Date: string): string;
    function CreateSignature(date, Region, Service, StringToSign: String): string;

    function CreateCanonicalURI(uri: string): string;
    function CreateCanonicalQueryString(var Params: TStringList): string;
    function CreateCanonicalHeaders(Headers: TStringList): string;
    function CreateCanonicalPayload(payload: string): string;
  public
    function Calculate(Request: IHTTPRequest): string; override;
    function CalculateToQuery(Request: IHTTPRequest; var Headers: string): String; override;
  end;

const
  Algoritimo = 'AWS4-HMAC-SHA256';
  TipoReq = 'aws4_request';

implementation

{ TAWSSignatureHMAC256 }

constructor TAWSSignatureHMAC256.Create(const AccessKey, DataStamp,
  RegionName, ServiceName: string);
begin
  inherited Create;
  FAccessKey:= AccessKey;
  FDataStamp:= DataStamp;
  FRegionName:= RegionName;
  FServiceName:= ServiceName;
end;

constructor TAWSSignatureHMAC256.Create(const AccessKey, SecretKey, DataStamp,
  RegionName, ServiceName: string);
begin
  inherited Create;
  FAccessKey:= AccessKey;
  FSecretKey:= SecretKey;
  FDataStamp:= DataStamp;
  FRegionName:= RegionName;
  FServiceName:= ServiceName;
end;

class function TAWSSignatureHMAC256.New(const AccessKey, DataStamp,
  RegionName, ServiceName: string): IAWSSignatureHMAC256;
begin
  Result := Create(AccessKey, DataStamp, RegionName, ServiceName);
end;

class function TAWSSignatureHMAC256.New(const AccessKey, SecretKey, DataStamp,
  RegionName, ServiceName: string): IAWSSignatureHMAC256;
begin
  Result := Create(AccessKey, SecretKey, DataStamp, RegionName, ServiceName);
end;

function TAWSSignatureHMAC256.AccessKey: string;
begin
  Result := FAccessKey;
end;

function TAWSSignatureHMAC256.SecretKey: string;
begin

end;

function TAWSSignatureHMAC256.DataStamp: string;
begin
  Result := FDataStamp;
end;

function TAWSSignatureHMAC256.RegionName: string;
begin
  Result := FRegionName;
end;

function TAWSSignatureHMAC256.ServiceName: string;
begin
  Result := FServiceName;
end;

function TAWSSignatureHMAC256.Signature: TSHA256Digest;
var
  oSHA256: TSHA256Digest;
begin
  HMAC_SHA256(UTF8Encode('AWS4'+FSecretKey), UTF8Encode(FDataStamp), oSHA256);
  HMAC_SHA256(oSHA256, UTF8Encode(FRegionName), oSHA256);
  HMAC_SHA256(oSHA256, UTF8Encode(FServiceName), oSHA256);
  HMAC_SHA256(oSHA256, UTF8Encode('aws4_request'), oSHA256);
  Result := oSHA256;
end;

{ TAWSSignatureVersion4 }

function TAWSSignatureVersion4.BuildHeader(const Header: String): String;
var
  i: Integer;
  List: TStringList;
begin
  List := TStringList.Create;
  List.Text:=Header;
  List.LineBreak:=#10;
  List.NameValueSeparator:=':';
  List.Sorted:=True;
  List.Sort;
  Result := '';
  for i := 1 to List.Count - 1 do
    Result := Result + List[i]+#10;

end;

procedure TAWSSignatureVersion4.SignedHeaders(const Header: String; var ToSing, ToCanonical: String);
var
  i: Integer;
  List: TStringList;
  Name, Value: String;
begin
  List := TStringList.Create;
  List.Text:=Header;
  List.LineBreak:=#10;
  List.NameValueSeparator:=':';
  List.Sorted:=True;
  List.Sort;
  for i := 0 to List.Count - 1 do
    begin
      List.GetNameValue(i, Name, Value);
      ToSing := ToSing + LowerCase(Name);
      ToCanonical := ToCanonical + LowerCase(Name)+':'+Value+#10;
    end;
end;

function TAWSSignatureVersion4.CreatePresignedURL(Request: IHTTPRequest): string;
var
  query, header: TStringList;
  LDateFmt: string;
  LAwsDateTime: String;
  LDateUTCNow: TDateTime;
  LCanonicalRequest, LStringToSign, LSignature: String;
  i: integer;
begin
  LDateUTCNow:= NowUTC;
  LDateFmt:= FormatDateTime('yyyymmdd', LDateUTCNow);
  LAwsDateTime:= FormatDateTime('yyyymmdd', LDateUTCNow)+'T'+FormatDateTime('hhnnss', LDateUTCNow)+'Z';
  query := TStringList.Create;
  header:= TStringList.Create;
  try
    query.Add('X-Amz-Algorithm=' + Algoritimo);
    query.Add('X-Amz-Credential=' + Credentials.AccessKeyId + '/' + CreateCredentialScope(LDateFmt, Credentials.RegionName, Request.ServiceName));
    query.Add('X-Amz-Date=' + LAwsDateTime);
    query.Add('X-Amz-Expires=86400');
    query.Add('X-Amz-SignedHeaders=' + CreateSignedHeaders(Request));

    header.Add('Host=' + Request.SubDomain+ '.' +Request.Domain);
    LCanonicalRequest:= Trim(CreateCanonicalRequest(Request, query, header, 'UNSIGNED-PAYLOAD'));
    LStringToSign := CreateStringToSign(Request, LCanonicalRequest, LAwsDateTime, LDateFmt);
    LSignature := CreateSignature(LDateFmt, Credentials.RegionName, Request.ServiceName, Trim(LStringToSign));
    query.Sort;
    query.StrictDelimiter:= True;
    query.Add('X-Amz-Signature=' + LSignature);
    Result := query.Join('&');
  finally
    query.Free;
    header.Free;
  end;
end;

function TAWSSignatureVersion4.CreateCredentialScope(date, region,
  service: string): string;
begin
  Result := date + '/' + region + '/' + service + '/' + TipoReq;
end;

function TAWSSignatureVersion4.CreateSignedHeaders(Request: IHTTPRequest
  ): String;
var
  LSignedHeader, LCanonical: string;
  LHeader: String;
begin
  LHeader := 'Host:' + Request.Domain;
  SignedHeaders(LHeader, LSignedHeader, LCanonical);
  Result := LSignedHeader;
end;

function TAWSSignatureVersion4.CreateCanonicalRequest(Request: IHTTPRequest;
  Queries, Headers: TStringList; Payload: string): string;
var
  LRes: TStringList;
  i: integer;
begin
  Result := '';
  LRes := TStringList.Create;
  try
    LRes.Add(UpperCase(Request.Method));
    LRes.Add(CreateCanonicalURI('/'));
    LRes.Add(CreateCanonicalQueryString(Queries));
    LRes.Add(CreateCanonicalHeaders(Headers));
    LRes.Add(CreateSignedHeaders(Request));
    LRes.Add(CreateCanonicalPayload(Payload));
    Result := LRes.Join(#10);
  finally
    LRes.Free;
  end;
end;

function TAWSSignatureVersion4.CreateStringToSign(Request: IHTTPRequest;
  CanonicalRequest, Time, Date: string): string;
var
  LRes: TStringList;
  i: integer;
begin
  Result := '';
  LRes := TStringList.Create;
  try
    LRes.Add(Algoritimo);
    LRes.Add(Time);
    LRes.Add(CreateCredentialScope(Date, Credentials.RegionName, Request.ServiceName));
    LRes.Add(SHA256(UTF8Encode(CanonicalRequest)));
    for i := 0 to LRes.Count - 1 do begin
      Result := Result + #10 + Trim(LRes[i]);
    end;
    Result := Trim(Result);
  finally
    LRes.Free;
  end;
end;

function TAWSSignatureVersion4.CreateSignature(date, Region, Service,
  StringToSign: String): string;
var
  LSignatureHMAC256: IAWSSignatureHMAC256;
  LSigKey, LSHA256: TSHA256Digest;
begin
  LSignatureHMAC256 := TAWSSignatureHMAC256.New(Credentials.AccessKeyId, Credentials.SecretKey, date , Region, Service);
  LSigKey := LSignatureHMAC256.Signature;
  HMAC_SHA256(LSigKey, StringToSign, LSHA256);
  Result := SHA256DigestToString(LSHA256);
end;

function TAWSSignatureVersion4.CreateCanonicalURI(uri: string): string;
begin
  Result := '/';
  if (uri[Length(uri) - 1] = '/') then
    Result := '/';
end;

function TAWSSignatureVersion4.CreateCanonicalQueryString(var Params: TStringList
  ): string;
var
  i: integer;
  LQlines: TStringDynArray;
  LtmpVal: string;
begin
  Result := '';
  for i := 0 to Params.Count - 1 do begin
     LQlines := SplitString(Params[i], '=');
     LtmpVal := EncodeURLElement(LQlines[0]) + '=' + EncodeURLElement(LQlines[1]);
     Params[i] := LtmpVal;
  end;
  Result := Params.Join('&');
end;

function TAWSSignatureVersion4.CreateCanonicalHeaders(Headers: TStringList
  ): string;
var
  i: integer;
  Llines: TStringDynArray;
  LRes: TStringList;
begin
  Result := '';
  LRes := TStringList.Create;
  try
    for i := 0 to Headers.Count - 1 do begin
       Llines:= SplitString(Headers[i], '=');
       LRes.Add(LowerCase(Llines[0])+':'+Llines[1]);
       //LRes.Add(#10);
    end;
    Result := Trim(LRes.Text) + #10;
  finally
    LRes.Free;
  end;
end;

function TAWSSignatureVersion4.CreateCanonicalPayload(payload: string): string;
begin
  if payload = 'UNSIGNED-PAYLOAD' then begin
    Result := payload;
    Exit;
  end;

  Result := SHA256(payload);
end;

function TAWSSignatureVersion4.Calculate(Request: IHTTPRequest): string;
var
  Header: string;
  Credencial: String;
  Escopo: String;
  DateFmt: String;
  AwsDateTime: String;
  Metodo: String;
  Canonical: String;
  CanonicalURI: String;
  CanonicalQuery: String;
  CanonicalHeaders: String;
  SignedHeader: String;
  PayLoadHash: String;
  CanonicalRequest: String;
  StringToSign: String;
  Signature: String;
  AuthorizationHeader: String;
  Assinatura: TSHA256Digest;
  SignatureHMAC256: IAWSSignatureHMAC256;
  oSHA256: TSHA256Digest;
  LDateUTCNow: TDateTime;
begin
  LDateUTCNow := NowUTC;
  DateFmt:= FormatDateTime('yyyymmdd', LDateUTCNow);
  AwsDateTime:= FormatDateTime('yyyymmdd', LDateUTCNow)+'T'+FormatDateTime('hhnnss', LDateUTCNow)+'Z';
  Metodo:= Request.Method;
  CanonicalURI:=EncodeTriplet(Request.Resource, '%', [':']);
  CanonicalQuery:='';

  Header := 'Host:' + Request.Domain + #10 ;
  CanonicalHeaders:= Header + 'X-Amz-Date:' + AwsDateTime + #10 + 'X-Amz-Content-Sha256:' + SHA256('') + #10 + Request.CanonicalizedAmzHeaders;
  SignedHeaders(Header+CanonicalHeaders, SignedHeader, Canonical);
  PayLoadHash:= SHA256(''); //Request.SubResource

  CanonicalRequest := Metodo + #10 + CanonicalURI + #10 + CanonicalQuery + #10
                    + Canonical + #10 + SignedHeader + #10 + PayLoadHash;

  SignatureHMAC256 := TAWSSignatureHMAC256.New(Credentials.AccessKeyId, DateFmt, Credentials.RegionName, Request.ServiceName);
  Credencial:= DateFmt + '/' + SignatureHMAC256.RegionName + '/' + Request.ServiceName + '/' + TipoReq;
  Escopo:= Credentials.AccessKeyId + '/' + Credencial;
  StringToSign := Algoritimo + #10 +  AwsDateTime + #10 + Credencial + #10 + SHA256( UTF8Encode(CanonicalRequest));

  Assinatura:= SignatureHMAC256.Signature;
  HMAC_SHA256(Assinatura, UTF8Encode(StringToSign), oSHA256);
  Signature := SHA256DigestToString(oSHA256);

  AuthorizationHeader := 'Authorization:' + Algoritimo + ' ' + 'Credential=' + Escopo + ', ' +
                         'SignedHeaders=' + SignedHeader + ', ' + 'Signature=' + Signature;

  Result := BuildHeader(CanonicalHeaders)
            + AuthorizationHeader
            ;

end;

function TAWSSignatureVersion4.CalculateToQuery(Request: IHTTPRequest;
  var Headers: string): String;
begin
  Headers:= '';
  Result := CreatePresignedURL(Request);
end;

{ TAWSCredentials }

constructor TAWSCredentials.Create(const AccessKeyId, SecretKey: string;
  UseSSL: Boolean);
begin
  FAccessKeyId := AccessKeyId;
  FSecretKey := SecretKey;
  FSSL := UseSSL;
end;

constructor TAWSCredentials.Create(const AccessKeyId, SecretKey: string;
  UseSSL: Boolean; RegionName: string);
begin
  FAccessKeyId:= AccessKeyId;
  FSecretKey:= SecretKey;
  FSSL:= UseSSL;
  FRegionName:= RegionName;
end;

class function TAWSCredentials.New(const AccessKeyId, SecretKey: string;
  UseSSL: Boolean): IAWSCredentials;
begin
  Result := Create(AccessKeyId, SecretKey, UseSSL);
end;

class function TAWSCredentials.New(const AccessKeyId, SecretKey: string;
  UseSSL: Boolean; RegionName: string): IAWSCredentials;
begin
  Result := Create(AccessKeyId, SecretKey, UseSSL, RegionName);
end;

function TAWSCredentials.AccessKeyId: string;
begin
  Result := FAccessKeyId;
end;

function TAWSCredentials.SecretKey: string;
begin
  Result := FSecretKey;
end;

function TAWSCredentials.UseSSL: Boolean;
begin
  Result := FSSL;
end;

function TAWSCredentials.RegionName: string;
begin
  Result := FRegionName;
end;

{ TAWSAbstractSignature }

constructor TAWSAbstractSignature.Create(Credentials: IAWSCredentials);
begin
  inherited Create;
  FCredentials := Credentials;
end;

class function TAWSAbstractSignature.New(
  Credentials: IAWSCredentials): IAWSSignature;
begin
  Result := Create(Credentials);
end;

function TAWSAbstractSignature.Credentials: IAWSCredentials;
begin
  Result := FCredentials;
end;

{ TAWSSignatureVersion1 }

function TAWSSignatureVersion1.Calculate(Request: IHTTPRequest): string;
var
  H: string;
  DateFmt: string;
begin
  DateFmt := RFC822DateTime(Now);
  H := Request.Method + #10
     + Request.ContentMD5 + #10
     + Request.ContentType + #10
     + DateFmt + #10;

  if Request.CanonicalizedAmzHeaders <> EmptyStr then
    H := H + Request.CanonicalizedAmzHeaders + #10;

  H := H + Request.CanonicalizedResource;

  Result := 'Date: ' + DateFmt + #10;

  if Request.CanonicalizedAmzHeaders <> EmptyStr then
    Result := Result + Request.CanonicalizedAmzHeaders + #10;

  Result := Result + 'Authorization: AWS '
          + Credentials.AccessKeyId + ':'
          + EncodeBase64(HMAC_SHA1(H, Credentials.SecretKey))
end;

function TAWSSignatureVersion1.CalculateToQuery(Request: IHTTPRequest;
  var Headers: string): String;
begin

end;

{ TAWSSignatureVersion3 }

function TAWSSignatureVersion3.Calculate(Request: IHTTPRequest): string;
var
  DateFmt: string;
begin
  DateFmt := RFC822DateTime(Now);
  Result := 'Date: ' + DateFmt + #10
          + 'Host: ' + Request.Domain + #10
          + 'X-Amzn-Authorization: '
          + 'AWS3-HTTPS AWSAccessKeyId=' + Credentials.AccessKeyId + ','
          + 'Algorithm=HMACSHA1,Signature='+EncodeBase64(HMAC_SHA1(DateFmt, Credentials.SecretKey));
end;

function TAWSSignatureVersion3.CalculateToQuery(Request: IHTTPRequest;
  var Headers: string): String;
begin

end;

{ TStringListHelper }

function TStringListHelper.Join(Separator: char): string;
var
  i: integer;
begin
  for i := 0 to Self.Count - 1 do begin
    if i <> Self.Count - 1 then
      Result := Result + Self[i] + Separator
    else
      Result := Result + Self[i];
  end;
end;

end.
