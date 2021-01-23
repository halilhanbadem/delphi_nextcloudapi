# NextCloud API for Delphi

You can run the NextCloud API, which is designed for Delphi and prepared with the components that come with the Delphi IDE, with this file.
Note: I didn't need the sample. I have an example. If you need it, open Issue.

# Usage


## Set Information and Connection
```
 NCAPI := TNextCloudAPI.create;
 NCAPI.UserName := 'xxxx';
 NCAPI.Password := 'xxxx';
 NCAPI.Server := 'https://nextcloud_host_name.com.tr/remote.php/dav/files/username/';
 NCAPI.setConfig;
 ```

PS: Here you can define the NCAPI variable globally. Variable type: "TNextCloudAPI"

## File Download

```
NCAPI.downloadFile('Document.txt', 'D:\NC\Document.txt');
```

PS: Since the "document.txt" file is in the root folder, it is given directly as a name. For files in another folder: You can use it as "/otherfolder/name.txt".

## File Upload

`function TNextCloudAPI.uploadFile(SourcePath, DestPath: String): Boolean;`

PS: Use this function and just give the parameters. So much.

## Get File List
`procedure TNextCloudAPI.getFileList(Folder: String);`

PS: You can use this function to view files (including subfolders) within a folder.

##  Create File
`function TNextCloudAPI.createFolder(FileName: String): Boolean;`

PS: Call this function to create the file.

## Important

You need to call setConfig procedure before performing operations such as downloading, uploading files. Thus, you can use unidentified information in the link. You must make the settings mentioned in the first title. This application uses IdWebDAV and its dependencies. Since it is open source, you can develop it. Accordingly, to get the relevant file information (GetFiles); You can access the information of the selected file with the definition of  `FileGet: TFileInfo;`.

The information you can access is: FilePath, FileName, FileSize, FileDate and  IsFolder. IsFolder tells you whether the object is a file or a folder. Here is a sample code to get a list of folders. This code will pull the list of files in your root folder. It creates the image of those files and folders in the folder you specified.

```
procedure TfMain.Button2Click(Sender: TObject);
var
 FileName: String;
begin
 NCAPI.getFileList('');
 CreateDir('D:\NC\');
 for FileName in NCAPI.FileDB.Keys do
  begin
   if NCAPI.FileDB.Items[FileName].IsFolder then
    begin
     CreateDir('D:\NC\' + TIdURI.URLDecode(NCAPI.FileDB.Items[FileName].FileName));
    end else
    begin
     FileCreate('D:\NC\' + TIdURI.URLDecode(NCAPI.FileDB.Items[FileName].FileName));
    end;
  end;
end;
```
And don't forget to destroy the object at the end of your actions! 
```
FreeAndNil(NCAPI);
```

Thanks for supported!
