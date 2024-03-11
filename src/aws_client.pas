{
    AWS
    Copyright (c) 2013-2018 Marcos Douglas B. Santos

    See the file LICENSE.txt, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit aws_client;

{$i aws.inc}

interface

uses
  //rtl
  sysutils,
  classes,
  //synapse
  synautil,
  //aws
  aws_credentials,
  aws_http;

type
  IAWSRequest = IHTTPRequest;

  IAWSResponse = IHTTPResponse;

  IAWSClient = interface(IInterface)
  ['{9CE71A17-9ADC-4FC1-96ED-8E9C704A988C}']
    function Send(Request: IAWSRequest): IAWSResponse;
  end;

  TAWSRequest = THTTPRequest;

  TAWSResponse = THTTPResponse;

  { TAWSClient }

  TAWSClient = class sealed(TInterfacedObject, IAWSClient)
  private
    FSignature: IAWSSignature;
    FServiceName: String;
    function MakeURL(const SubDomain, Domain, SubResource, Query: string): string;
  public
    constructor Create(Signature: IAWSSignature; ServiceName: string);
    class function New(Signature: IAWSSignature; ServiceName: string): IAWSClient;
    function Send(Request: IAWSRequest): IAWSResponse;
  end;

implementation

{ TAWSClient }

function TAWSClient.MakeURL(const SubDomain, Domain, SubResource, Query: string
  ): string;
var
  Qry: String;
begin
  Result := '';
  if FSignature.Credentials.UseSSL then
    Result += 'https://'
  else
    Result += 'http://';
  if SubDomain <> '' then
    Result += SubDomain + '.';
  if Query <> '' then
    Qry:= '/?' + Query;
  Result += Domain + SubResource + Qry;
end;

constructor TAWSClient.Create(Signature: IAWSSignature; ServiceName: string);
begin
  inherited Create;
  FSignature := Signature;
  FServiceName:= ServiceName;
end;

class function TAWSClient.New(Signature: IAWSSignature; ServiceName: string
  ): IAWSClient;
begin
  Result := Create(Signature, ServiceName);
end;

function TAWSClient.Send(Request: IAWSRequest): IAWSResponse;
var
  LQuery: string;
  LHeaders: TStringList;
  LUrl: string;
begin
  Request.ServiceName := FServiceName;
  LQuery:= FSignature.CalculateToQuery(Request, LHeaders);
  LUrl  := MakeURL(Request.SubDomain, Request.Domain, Request.Resource, LQuery);
  Result := THTTPSender.New(
     Request.Method,
     LHeaders,
     Request.ContentType,
     LUrl,
     Request.Stream,
     FServiceName
  )
  .Send;
end;

end.

