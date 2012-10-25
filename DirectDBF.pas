//
//---------------------------------------------------------------
//                                                               
//                                                               
//    The DBF access component for Delphi5--Delphi2007     
//                                                               
//    Version 1.02                                               
//    Update Date: 2010.1.                                    
//    Author: Jopher(W.G.Z.)                                     
//    QQ: 779545524                                              
//    Email: Jopher@189.cn  or wpy020327@163.com                 
//                                                               
//    Copyright(C) Jopher Software Studio. All rights reserved   
//                                                               
//                                                               
//---------------------------------------------------------------
//
unit DirectDBF;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, ExtCtrls, StdCtrls;

type
   THandle=Integer;

type
   FieldRecord=record
      FieldName: string;                    
      FieldType: string;                    
      FieldWidth: integer;                  
      DecimalWidth: integer;                
      offset: integer;                      
end;

type
   TDirectDBF=class(TComponent)

   Private
      fFileName: string;                    
      fExclusive: Boolean;                  
      fFileHandle: THandle;                 
      fRecordCount: Longint;                
      fHeaderSize: smallint;                
      fRecordSize: smallint;                
      fFieldCount: integer;                 
      fFieldList: array of FieldRecord;     
      fOpened: boolean;                     
      fCursorPtr: longint;                  
      fEof: boolean;                        
      fBof: Boolean;                        
      fRecBuffer: array [0..65535] of char; 
      fRecordStatus: integer;               
      fOnOpenSuccess: TNotifyEvent;         
      fOnOpenFail: TNotifyEvent;            
      fOnPostSuccess: TNotifyEvent;         
      fOnPostFail: TNotifyEvent;            
      fOnReadError: TNotifyEvent;           
      fOnWriteError: TNotifyEvent;          
      fAfterFetchRecord: TNotifyEvent;      
      fOnPackSuccess: TNotifyEvent;         
      fOnPackFail: TNotifyEvent;            
      procedure SetFileName(FileName: string);
      procedure SetExclusive(Exclusive: boolean);
      procedure DoOpen;

   Protected

   Public
      property RecordCount: Longint read fRecordCount;                
      property RecordSize: smallint read fRecordSize;                 
      property FieldCount: integer read fFieldCount;                  
      property Opened: boolean read fOpened;                          
      property RecNo: longint read fCursorPtr;                        
      property Eof: boolean read fEof;                                
      property Bof: Boolean read fBof;                                
      Constructor Create(AOwner: TComponent); override;               
      Destructor Destroy(); override;                                 
      procedure Open;
      procedure Close;
      procedure first;
      procedure last;
      procedure next;
      procedure Prior;
      procedure MoveBy(MoveCount: integer);
      procedure Append;
      procedure Edit;
      procedure post;
      procedure SetSmallIntValue(FieldName: string; IntValue: Smallint); 
      procedure SetLongIntValue(FieldName: string; LongIntValue: longint); 
      procedure SetStringValue(FieldName: string; StringValue: string); 
      procedure SetRealValue(FieldName: string; RealValue: real); 
      procedure SetDoubleValue(FieldName: string; DoubleValue: double); 
      procedure SetCurrencyValue(FieldName: string; CurrValue: Currency); 
      procedure SetBooleanValue(FieldName: string; BooleanValue: boolean); 
      procedure GetSmallIntValue(FieldName: string; var IntValue: Smallint); 
      procedure GetLongIntValue(FieldName: string; var LongIntValue: longint); 
      procedure GetStringValue(FieldName: string; var StringValue: string); 
      procedure GetRealValue(FieldName: string; var RealValue: real); 
      procedure GetDoubleValue(FieldName: string; var DoubleValue: double); 
      procedure GetCurrencyValue(FieldName: string; var CurrValue: Currency);
      procedure GetBooleanValue(FieldName: string; var BooleanValue: boolean);
      function IsDeleted: boolean;
      procedure GetFieldAttributes(FieldIndex: integer; var FieldName: string; var FieldType: string; var FieldWidth: integer; var FieldDecimalWidth: integer);
      procedure Delete;
      procedure DeleteAll;
      procedure Recall;
      procedure RecallAll;
      procedure Pack;

   published
      property DbfFileName: string read fFileName write SetFileName;                          
      property Exclusive: Boolean read fExclusive write SetExclusive;                         
      property OnOpenSuccess: TNotifyEvent read fOnOpenSuccess write fOnOpenSuccess;          
      property OnOpenFail: TNotifyEvent read fOnOpenFail write fOnOpenFail;                   
      property OnPostSuccess: TNotifyEvent read fOnPostSuccess write fOnPostSuccess;          
      property OnPostFail: TNotifyEvent read fOnPostFail write fOnPostFail;                   
      property OnReadError: TNotifyEvent read fOnReadError write fOnReadError;                
      property OnWriteError: TNotifyEvent read fOnWriteError write fOnWriteError;             
      property AfterFetchRecord: TNotifyEvent read fAfterFetchRecord write fAfterFetchRecord; 
      property OnPackSuccess: TNotifyEvent read fOnPackSuccess write fOnPackSuccess;          
      property OnPackFail: TNotifyEvent read fOnPackFail write fOnPackFail;                   

end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Data Access', [TDirectDBF]);
end;

constructor TDirectDBF.Create(AOwner: TComponent);
begin
   inherited;
      fFileName:='';
      fExclusive:=true;
      fFileHandle:=-1;
      fRecordCount:=0;
      fHeaderSize:=0;
      fRecordSize:=0;
      fFieldCount:=0;
      setlength(fFieldList,0);
      fCursorPtr:=-1;
      fOpened:=false;
      fEof:=true;
      fBof:=true;
end;

destructor TDirectDBF.Destroy;
begin
   if fOpened then
      begin
         fileclose(fFileHandle);
         fopened:=false;
         fFileHandle:=-1;
         fCursorPtr:=-1;
         fEof:=true;
         fBof:=true;
         fRecordCount:=0;
         fHeaderSize:=0;
         fRecordSize:=0;
         fFieldCount:=0;
         setlength(fFieldList,0);
      end;
  inherited;
end;

procedure TDirectDBF.SetFileName(FileName: string);
begin
   if fOpened then
      exit;
   fFileName:=FileName;
end;

procedure TDirectDBF.SetExclusive(Exclusive: boolean);
begin
   if fOpened then
      exit;
   fExclusive:=Exclusive;
end;

procedure TDirectDBF.Open;
begin
   if fOpened then
      begin
         if assigned(fOnOpenSuccess) then
            fOnOpensuccess(self);
         exit;
      end;
   if (trim(fFileName)='') or (not fileexists(fFileName)) then
      begin
         if assigned(fOnOpenFail) then
            fOnOpenFail(self);
         exit;
      end;
   DoOpen;
end;

procedure TDirectDBF.DoOpen;
var
   i,j,offset,bytes: integer;
begin
   if fExclusive then
      fFileHandle:=FileOpen(fFileName,fmOpenReadWrite)
   else
      fFileHandle:=FileOpen(fFileName,fmOpenReadWrite or fmShareDenyNone);
   if fFileHandle=-1 then
      begin
         if assigned(fOnOpenFail) then
            fOnOpenFail(self);
         exit;
      end;
   j:=fileread(fFileHandle,fRecBuffer,32);          
   if j<>32 then
      begin
         fileclose(fFileHandle);
         fFileHandle:=-1;
         if assigned(fOnOpenFail) then
            fOnOpenFail(self);
         exit;
      end;
   move(fRecBuffer[4],fRecordCount,4);           
   move(fRecBuffer[8],fHeaderSize,2);            
   move(fRecBuffer[10],fRecordSize,2);           
   fFieldCount:=0;
   setlength(fFieldList,0);
   offset:=1;
   while true do
      begin
         FileRead(fFileHandle,fRecBuffer,32);
         if ord(fRecBuffer[0])=13 then
            break;
         j:=fFieldCount;
         inc(fFieldCount);
         setlength(fFieldList,fFieldCount);
         fFieldList[j].FieldName:='';
         for i:=0 to 10 do
            begin
               if fRecBuffer[i]=char(0) then
                  break;
               fFieldList[j].FieldName:=fFieldList[j].FieldName+fRecBuffer[i];
            end;
         fFieldList[j].FieldName:=uppercase(trim(fFieldList[j].FieldName));
         fFieldList[j].FieldType:=fRecBuffer[11];
         fFieldList[j].FieldWidth:=ord(fRecBuffer[16]);
         fFieldList[j].DecimalWidth:=ord(fRecBuffer[17]);
         fFieldList[j].offset:=offset;
         offset:=offset+fFieldList[j].FieldWidth;
      end;
   fileseek(fFileHandle,fHeaderSize,0);
   fillchar(fRecBuffer,fRecordSize,0);
   fOpened:=true;
   if fRecordCount=0 then
      begin
         fEof:=true;
         fBof:=true;
         fCursorPtr:=-1;
         fRecordStatus:=0;
         if assigned(fOnOpenSuccess) then
            fOnOpensuccess(self);
         exit;
      end;
   if assigned(fOnOpenSuccess) then
      fOnOpensuccess(self);
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,fHeaderSize,0);
   fEof:=false;
   fBof:=false;
   fCursorPtr:=0;
   fRecordStatus:=1;
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.Close;
begin
   if not fOpened then
      exit;
   fileclose(fFileHandle);
   fopened:=false;
   fFileHandle:=-1;
   fCursorPtr:=-1;
   fEof:=true;
   fBof:=true;
   fRecordCount:=0;
   fHeaderSize:=0;
   fRecordSize:=0;
   fFieldCount:=0;
   setlength(fFieldList,0);
   fRecordStatus:=0;
end;

procedure TDirectDBF.first;
var
   bytes: integer;
begin
   if (not fOpened) or (fRecordCount=0) or (fCursorPtr=0) then
      exit;
   fCursorPtr:=0;
   fileseek(fFileHandle,fHeaderSize,0);
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,fHeaderSize,0);
   fEof:=false;
   fBof:=false;
   fRecordStatus:=1;
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.last;
var
   offset: longint;
   bytes: integer;
begin
   if (not fOpened) or (fCursorPtr>=(fRecordCount-1)) or (fRecordCount=0) then
      exit;
   fCursorPtr:=fRecordCount-1;
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,offset,0);
   fEof:=false;
   fBof:=false;
   fRecordStatus:=1;
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.next;
var
   offset: longint;
   bytes: integer;
begin
   if (not fOpened) or (fRecordCount=0) then
      exit;
   if fCursorPtr>=(fRecordCount-1) then
      begin
         fCursorPtr:=fRecordCount;
         fEof:=true;
         fRecordStatus:=0;
         exit;
      end;
   inc(fCursorPtr);
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,offset,0);
   fEof:=false;
   fBof:=false;
   fRecordStatus:=1;
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.Prior;
var
   offset: longint;
   bytes: integer;
begin
   if (not fOpened) or (fRecordCount=0) then
      exit;
   if fCursorPtr<=0  then
      begin
         fCursorPtr:=-1;
         fBof:=true;
         fRecordStatus:=0;
         exit;
      end;
   dec(fCursorPtr);
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,offset,0);
   fEof:=false;
   fBof:=false;
   fRecordStatus:=1;
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.MoveBy(MoveCount: integer);
var
   offset: longint;
   bytes: integer;
begin
   if not fOpened then
      exit;
   if (MoveCount=0) or (fRecordCount=0) then
      exit;
   if MoveCount>0 then
      begin
         if (fCursorPtr+MoveCount)>=fRecordCount then
            fCursorPtr:=fRecordCount-1
         else
            fCursorPtr:=fCursorPtr+MoveCount;
         offset:=fHeaderSize+fCursorPtr*fRecordSize;
         fileseek(fFileHandle,offset,0);
         bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
         fileseek(fFileHandle,offset,0);
      end
   else
      begin
         if (fCursorPtr+MoveCount)<0 then
            fCursorPtr:=0
         else
            fCursorPtr:=fCursorPtr+MoveCount;
         offset:=fHeaderSize+fCursorPtr*fRecordSize;
         fileseek(fFileHandle,offset,0);
         bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
         fileseek(fFileHandle,offset,0);
      end;
   fRecordStatus:=1;
   fEof:=false;
   fBof:=false;
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.Append;
begin
   if not fOpened then
      exit;
   fillchar(fRecBuffer,fRecordSize,0);
   fRecordStatus:=2;
end;

procedure TDirectDBF.Edit;
begin
   if not fOpened then
      exit;
   if fEof or fBof then
      exit;
   if fRecordStatus>=2 then
      exit;
   fRecordStatus:=3;
end;

procedure TDirectDBF.post;
var
   bytes,Offset,wb: longint;
   TmpBuffer: array [0..3] of char;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      begin
         if assigned(fOnPostFail) then
            fOnPostFail(self);
         exit;
      end;
   if fRecordStatus=2 then
      begin
         offset:=fHeaderSize+fRecordCount*fRecordSize;
         fileseek(fFileHandle,offset,0);
         fRecBuffer[fRecordSize]:=char(26);      
         wb:=fRecordSize+1;
      end
   else
      wb:=fRecordSize;
   bytes:=FileWrite(fFileHandle,fRecBuffer,wb);
   if bytes<wb then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         if assigned(fOnPostFail) then
            fOnPostFail(self);
         exit;
      end;
   if fRecordStatus=2 then
      begin
         fCursorPtr:=fRecordCount;
         inc(fRecordCount);
         fileseek(fFileHandle,4,0);
         move(fRecordCount,tmpBuffer,4);
         bytes:=filewrite(fFileHandle,tmpBuffer,4);
         offset:=fHeaderSize+fCursorPtr*fRecordSize;
         FileSeek(fFileHandle,offset,0);
         if bytes<4 then
            begin
               if assigned(fOnWriteError) then
                  fOnWriteError(self);
               if assigned(fOnPostFail) then
                  fOnPostFail(self);
               exit;
            end;
      end
   else
      begin
         offset:=fHeaderSize+fCursorPtr*fRecordSize;
         FileSeek(fFileHandle,offset,0);
      end;
   fRecordStatus:=1;
   if assigned(fOnPostSuccess) then
      fOnPostSuccess(self);
end;

procedure TDirectDBF.SetSmallIntValue(FieldName: string; IntValue: Smallint);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(IntValue,fRecBuffer[offset],2);
      end;
end;

procedure TDirectDBF.SetLongIntValue(FieldName: string; LongIntValue: longint);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(LongIntValue,fRecBuffer[offset],4);
      end;
end;

procedure TDirectDBF.SetStringValue(FieldName: string; StringValue: string);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(StringValue[1],fRecBuffer[offset],length(StringValue));
         for i:=length(stringvalue) to fFieldList[j].FieldWidth-1 do
            fRecBuffer[offset+i]:=' ';
      end;
end;

procedure TDirectDBF.SetRealValue(FieldName: string; RealValue: real);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(RealValue,fRecBuffer[offset],4);
      end;
end;

procedure TDirectDBF.SetDoubleValue(FieldName: string; DoubleValue: double);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(DoubleValue,fRecBuffer[offset],8);
      end;
end;

procedure TDirectDBF.SetBooleanValue(FieldName: string; BooleanValue: boolean);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         if BooleanValue then
            fRecBuffer[offset]:='Y'
         else
            fRecBuffer[offset]:='N';
      end;
end;

procedure TDirectDBF.SetCurrencyValue(FieldName: string; CurrValue: Currency);
var
   i,j,offset: integer;
begin
   if not fOpened then
      exit;
   if fRecordStatus<2 then
      exit;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(CurrValue,fRecBuffer[offset],8);
      end;
end;

procedure TDirectDBF.GetSmallIntValue(FieldName: string; var IntValue: Smallint);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         IntValue:=0;
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(fRecBuffer[offset],IntValue,2);
      end
   else
      IntValue:=0;
end;

procedure TDirectDBF.GetLongIntValue(FieldName: string; var LongIntValue: longint);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         LongIntValue:=0;
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(fRecBuffer[offset],LongIntValue,4);
      end
   else
      LongIntValue:=0;
end;

procedure TDirectDBF.GetStringValue(FieldName: string; var StringValue: string);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         StringValue:='';
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         setlength(StringValue,fFieldList[j].FieldWidth);
         move(fRecBuffer[offset],StringValue[1],fFieldList[j].FieldWidth);
      end
   else
      StringValue:='';
end;

procedure TDirectDBF.GetRealValue(FieldName: string; var RealValue: real);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         RealValue:=0;
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(fRecBuffer[offset],RealValue,4);
      end
   else
      RealValue:=0;
end;

procedure TDirectDBF.GetDoubleValue(FieldName: string; var DoubleValue: double);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         DoubleValue:=0;
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(fRecBuffer[offset],DoubleValue,8);
      end
   else
      DoubleValue:=0;
end;

procedure TDirectDBF.GetBooleanValue(FieldName: string; var BooleanValue: boolean);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         BooleanValue:=false;
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         BooleanValue:=(uppercase(fRecBuffer[offset])='Y');
      end
   else
      BooleanValue:=false;
end;

procedure TDirectDBF.GetCurrencyValue(FieldName: string; var CurrValue: Currency);
var
   i,j,offset: integer;
begin
   if not fOpened then
      begin
         CurrValue:=0;
         exit;
      end;
   j:=-1;
   for i:=0 to fFieldCount-1 do
      if fFieldList[i].FieldName=uppercase(FieldName) then
         begin
            j:=i;
            break;
         end;
   if j<>-1 then
      begin
         offset:=fFieldList[j].offset;
         move(fRecBuffer[offset],CurrValue,8);
      end
   else
      CurrValue:=0;
end;

function TDirectDBF.IsDeleted: boolean;
begin
   if not fOpened then
      begin
         Result:=true;
         exit;
      end;
   if fEof or fBof then
      begin
         Result:=true;
         exit;
      end;
   result:=(fRecBuffer[0]=char(42));
end;

procedure TDirectDBF.GetFieldAttributes(FieldIndex: integer; var FieldName: string; var FieldType: string; var FieldWidth: integer; var FieldDecimalWidth: integer);
begin
   if not fOpened then
      begin
         fieldname:='';
         fieldtype:='';
         fieldwidth:=0;
         fielddecimalwidth:=0;
         exit;
      end;
   if (FieldIndex<0) or (fieldindex>=fFieldCount) then
      begin
         fieldname:='';
         fieldtype:='';
         fieldwidth:=0;
         fielddecimalwidth:=0;
         exit;
      end;
   FieldName:=fFieldList[FieldIndex].FieldName;
   FieldType:=fFieldList[FieldIndex].FieldType;
   FieldWidth:=fFieldList[FieldIndex].FieldWidth;
   FieldDecimalWidth:=fFieldList[FieldIndex].DecimalWidth;
end;

procedure TDirectDBF.Delete;
var
   offset: longint;
   bytes: integer;
begin
   if not fOpened then
      exit;
   if fEof or fBof then
      exit;
   if fRecordStatus=2 then
      begin
         fCursorPtr:=fRecordCount-1;
         offset:=fHeaderSize+fCursorPtr*fRecordSize;
         fileseek(fFileHandle,offset,0);
         exit;
      end;
   fRecBuffer[0]:=char(42);
   bytes:=FileWrite(fFileHandle,fRecBuffer,1);
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   if bytes<>1 then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
      end;
end;

procedure TDirectDBF.DeleteAll;
var
   i,bytes: integer;
   offset: longint;
begin
   if not fOpened then
      exit;
   if fRecordCount=0 then
      exit;
   bytes:=1;
   for i:=0 to fRecordCount-1 do
      begin
         offset:=fHeaderSize+i*fRecordSize;
         fileseek(fFileHandle,offset,0);
         fRecBuffer[0]:=char(42);
         bytes:=filewrite(fFileHandle,fRecBuffer,1);
         if bytes<>1 then
            break;
      end;
   if bytes<>1 then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
   fCursorPtr:=fRecordCount-1;
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   fBof:=false;
   fEof:=false;
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,offset,0);
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.Recall;
var
   offset: longint;
   bytes: integer;
begin
   if not fOpened then
      exit;
   if fEof or fBof then
      exit;
   if fRecordStatus=2 then
      exit;
   fRecBuffer[0]:=char(32);
   bytes:=FileWrite(fFileHandle,fRecBuffer,1);
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   if bytes<>1 then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
end;

procedure TDirectDBF.RecallAll;
var
   i,bytes: integer;
   offset: longint;
begin
   if not fOpened then
      exit;
   if fRecordCount=0 then
      exit;
   bytes:=1;
   for i:=0 to fRecordCount-1 do
      begin
         offset:=fHeaderSize+i*fRecordSize;
         fileseek(fFileHandle,offset,0);
         fRecBuffer[0]:=char(32);
         bytes:=filewrite(fFileHandle,fRecBuffer,1);
         fileseek(fFileHandle,offset,0);
         if bytes<>1 then
            break;
      end;
   if bytes<>1 then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
   fCursorPtr:=fRecordCount-1;
   offset:=fHeaderSize+fCursorPtr*fRecordSize;
   fileseek(fFileHandle,offset,0);
   fBof:=false;
   fEof:=false;
   bytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
   fileseek(fFileHandle,offset,0);
   if bytes<fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
      end
   else
      begin
         if assigned(fAfterFetchRecord) then
            fAfterFetchRecord(self);
      end;
end;

procedure TDirectDBF.Pack;
var
   j,bytes,b,RBytes,WBytes: integer;
   okptr,badptr,RCount,Offset: longint;
   TmpFileName,tmpstr: string;
   TmpHandle: THandle;
begin
   if not fOpened then
      exit;
   if fRecordCount=0 then
      exit;
   OkPtr:=0;
   BadPtr:=0;
   RCount:=0;
   RBytes:=fRecordSize;
   WBytes:=fRecordSize;
   while BadPtr<fRecordCount do
      begin
         offset:=fHeaderSize+BadPtr*fRecordSize;
         fileseek(fFileHandle,offset,0);
         RBytes:=fileread(fFileHandle,fRecBuffer,fRecordSize);
         if rbytes<>fRecordSize then
            break;
         if fRecBuffer[0]<>char(42) then
            begin
               offset:=fHeaderSize+OkPtr*fRecordSize;
               fileseek(fFileHandle,offset,0);
               wbytes:=filewrite(fFileHandle,fRecBuffer,fRecordSize);
               inc(okptr);       
               inc(RCount);      
            end;
         if wbytes<>fRecordSize then
            break;
         inc(BadPtr);     
      end;
   if RBytes<>fRecordSize then
      begin
         if assigned(fOnReadError) then
            fOnReadError(self);
         exit;
      end;
   if WBytes<>fRecordSize then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
   fileclose(fFileHandle);
   tmpfilename:=extractfilepath(fFileName);
   tmpstr:=extractfilename(fFileName);
   j:=pos('.',tmpstr);
   if j>0 then
      tmpstr:=copy(tmpstr,1,j-1);
   tmpfilename:=tmpfilename+tmpstr+'.tmp';
   if not renamefile(fFileName,tmpfilename) then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
   fFileHandle:=FileCreate(fFileName);
   if fFileHandle=-1 then
      begin
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
   tmpHandle:=FileOpen(tmpfilename,fmOpenRead);
   if tmphandle=-1 then
      begin
         fileclose(fFileHandle);
         if assigned(fOnWriteError) then
            fOnWriteError(self);
         exit;
      end;
   Offset:=fHeaderSize+RCount*fRecordSize;        
   while true do
      begin
         if offset>=60*1024 then
            b:=60*1024
         else
            b:=offset;
         bytes:=FileRead(TmpHandle,fRecBuffer,b);
         filewrite(fFileHandle,fRecBuffer,bytes);
         offset:=offset-b;
         if offset<=0 then
            begin
               fRecBuffer[0]:=char(26);
               filewrite(fFileHandle,fRecBuffer,1);
               move(RCount,fRecBuffer,4);
               fileseek(fFileHandle,4,0);
               filewrite(fFileHandle,fRecBuffer,4);
               break;
            end;
      end;
   fileclose(fFileHandle);
   fileclose(tmpHandle);
   deletefile(tmpfilename);
   fOpened:=false;
   DoOpen;
end;

end.
