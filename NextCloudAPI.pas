{
	
 _   _       _ _ _   _   _               ____    _    ____  _____ __  __ 
| | | | __ _| (_) | | | | | __ _ _ __   | __ )  / \  |  _ \| ____|  \/  |
| |_| |/ _` | | | | | |_| |/ _` | '_ \  |  _ \ / _ \ | | | |  _| | |\/| |
|  _  | (_| | | | | |  _  | (_| | | | | | |_) / ___ \| |_| | |___| |  | |
|_| |_|\__,_|_|_|_| |_| |_|\__,_|_| |_| |____/_/   \_\____/|_____|_|  |_|
                                                                         

 History: 11/08/2020 
 Developer: Halil Han BADEM
}

unit NextCloudAPI;

interface

 uses
    IdBaseComponent,
    IdComponent,
    IdTCPConnection,
    IdTCPClient,
    IdHTTP,
    IdWebDAV,
    IdIOHandler,
    IdIOHandlerSocket,
    IdIOHandlerStack,
    IdSSL,
    IdSSLOpenSSL,
    XMLDoc,
    XMLIntf,
    IdCoder,
    IdCoder3to4,
    IdCoderMIME,
    Vcl.ComCtrls,
    System.Classes,
    Generics.Collections,
    SysUtils,
    VCL.Forms,
    VCL.Dialogs;



type
 TFileInfo = class
   FilePath, FileName, FileSize, FileDate: String;
   IsFolder: Boolean;
 end;


type
 TNextCloudAPI = class
     constructor create;
     destructor destroy; override;
   private
     IdWebDAVC: TIdWebDAV;
     SSLHand: TIdSSLIOHandlerSocketOpenSSL;
     IdEncoderMIME1: TIdEncoderMIME;
     FUserName, FPassword, FServer: String;
   public
     FileDB: TDictionary<String, TFileInfo>;
     FileGet: TFileInfo;
     procedure setConfig;
     procedure getFileList(Folder: String);
     function downloadFile(FilePath: String; DestPath: String): Boolean;
     function uploadFile(SourcePath: String; DestPath: String): Boolean;
     function deleteFile(FileName: String): Boolean;
     function createFolder(FileName: String): Boolean;
   published
     property UserName: String read FUserName write FUserName;
     property Password: String read FPassword write FPassword;
     property Server: String read FServer write FServer;
 end;

implementation

{ TNextCloudAPI }

constructor TNextCloudAPI.create;
begin
  inherited;
 IdWebDAVC := TIdWebDAV.Create;
 SSLHand := TIdSSLIOHandlerSocketOpenSSL.Create;
 IdEncoderMIME1 := TIdEncoderMIME.Create;
 SSLHand.SSLOptions.SSLVersions := [sslvTLSv1_2];
 SSLHand.SSLOptions.Method := sslvTLSv1_2;
 IdWebDAVC.IOHandler := SSLHand;
 FileDB := TDictionary<String, TFileInfo>.Create;
end;

function TNextCloudAPI.createFolder(FileName: String): Boolean;
begin
 try
  IdWebDAVC.DAVMakeCollection(Server + FileName);
  Result := True;
 except
  Result := False;
 end;
end;

function TNextCloudAPI.deleteFile(FileName: String): Boolean;
begin
 try
  IdWebDAVC.DAVDelete(Server + FileName);
  Result := True;
 except
  Result := False;
 end;
end;

destructor TNextCloudAPI.destroy;
var
 sItem: String;
begin
 IdWebDAVC.Free;
 SSLHand.Free;
 IdEncoderMIME1.Free;

 for sItem in FileDB.Keys do
 begin
  FileDB.Items[sItem].Free;
 end;

 FreeAndNil(FileDB);
  inherited;
end;

function TNextCloudAPI.downloadFile(FilePath, DestPath: String): Boolean;
var
 FileStream: TFileStream;
begin
 FileStream := TFileStream.Create(DestPath, fmCreate);
 try
  IdWebDAVC.Get(Server + FilePath, FileStream);
  Result := True;
  FileStream.Free;
 except
  Result := False;
  FileStream.Free;
 end;
end;

procedure TNextCloudAPI.getFileList(Folder: String);
var
 ResponseXML: TStringStream;
 XMLFile: TXMLDocument;
 MainNode, ChildNode: IXMLNode;
 I: Integer;
 Keys: String;
begin
 ResponseXML := TStringStream.Create;
 IdWebDAVC.DAVPropFind(Server + Folder, nil, ResponseXML, '1');

 XMLFile := TXMLDocument.Create(Application);
 try
   XMLFile.LoadFromXML(ResponseXML.DataString);
   XMLFile.Active := True;
   MainNode := XMLFile.DocumentElement;
   FileDB.Clear;

   for I := 0 to MainNode.ChildNodes.Count - 1 do
   begin
    ChildNode := MainNode.ChildNodes.Nodes[I];

    if Trim(ChildNode.ChildNodes['d:href'].Text) = ''  then
    begin
      continue;
    end;

    FileGet := TFileInfo.Create;
    FileGet.FilePath := ChildNode.ChildNodes['d:href'].Text;
    FileGet.FileDate := ChildNode.ChildNodes['d:propstat'].ChildNodes['d:prop'].ChildNodes['d:getlastmodified'].Text;
    FileGet.FileSize := ChildNode.ChildNodes['d:propstat'].ChildNodes['d:prop'].ChildNodes['d:getcontentlength'].Text;
    FileGet.IsFolder := Assigned(ChildNode.ChildNodes['d:propstat'].ChildNodes['d:prop'].ChildNodes['d:resourcetype'].ChildNodes.FindNode('d:collection'));

    if FileGet.IsFolder then
    begin
      FileGet.FileName := FileGet.FilePath;
      Delete(FileGet.FileName, Length(FileGet.FileName), 1);
      FileGet.FileName := StringReplace(FileGet.FileName, '/', '\', [rfReplaceAll, rfIgnoreCase]);
      FileGet.FileName := ExtractFileName(FileGet.FileName);
    end else
    begin
      FileGet.FileName := StringReplace(FileGet.FilePath, '/', '\', [rfReplaceAll, rfIgnoreCase]);
      FileGet.FileName := ExtractFileName(FileGet.FileName);
    end;

    FileDB.Add(FileGet.FilePath, FileGet);
   end;
 finally
   ResponseXML.Free;
   XMLFile.Free;
 end;
end;

procedure TNextCloudAPI.setConfig;
begin
 IdWebDAVC.Request.Username := UserName;
 IdWebDAVC.Request.Password := Password;
 IdWebDAVC.Request.CustomHeaders.Values['Authorization'] := 'Basic ' + IdEncoderMIME1.EncodeString(UserName + ':' + Password);
end;

function TNextCloudAPI.uploadFile(SourcePath, DestPath: String): Boolean;
var
 FileStream: TMemoryStream;
begin
 FileStream := TMemoryStream.Create;
 try
  FileStream.LoadFromFile(SourcePath);
  IdWebDAVC.DAVPut(Server + DestPath + ExtractFileName(SourcePath), FileStream);
  FileStream.Free;
  Result := True;
 except
  Result := False;
  FileStream.Free;
 end;

end;

end.
