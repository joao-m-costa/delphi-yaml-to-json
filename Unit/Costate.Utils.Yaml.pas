unit Costate.Utils.Yaml;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.JSON.Types;


type

  // Yaml utils
  TYamlUtils = record
  public
    type
      TYamlIdentation = 2..8;
      TJsonIdentation = 0..8;
  private
    // Token utility
    class function  InternalGetNextToken( var S: string; Delimiters: string): string; static;
    // JSON to YAML
    class procedure InternalJsonObjToYaml( AJSON: TJSONObject; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False ); static;
    class procedure InternalJsonArrToYaml( AJSON: TJSONArray; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False ); static;
    class function  InternalJsonValueToYaml( AJSON: TJSONValue ): string; static;
    // YAML to JSON
    class procedure InternalYamlObjToJson( AYAML, AOutStrings: TStrings; AIndentation: TJsonIdentation; AIndent: Integer; var ASrcLine: Integer; AYamlIndent: Integer; AFromArray: boolean = False ); static;
    class procedure InternalYamlArrToJson( AYAML, AOutStrings: TStrings; AIndentation: TJsonIdentation; AIndent: Integer; var ASrcLine: Integer; AYamlIndent: Integer ); static;
    class procedure InternalYamlValueToJson( const AYAML: string; var AName, AValue: string ); static;
    class function  InternalYamlNextText( AYAML: TStrings; var ACurrentLine, AIndentValue: Integer; var AIsArrayElement: boolean ): string; static;
    class procedure InternalYamlNextProps( AYAML: TStrings; const ACurrentLine, ACurrentIndent: Integer; var AIsArray, AIsObject: boolean; var ALevel: Integer ); static;
    class function  InternalYamlPrevLine( AYAML: TStrings; ACurrentLine: Integer ): Integer; static;
    class function  InternalYamlHasMoreText( AYAML: TStrings; ACurrentLine: Integer ): boolean; static;
  public
    // JSON to YAML
    class function  JsonToYaml( AJSON: string; AIndentation: TYamlIdentation = 2 ): string; overload; static;
    class function  JsonToYaml( AJSON: TJSONValue; AIndentation: TYamlIdentation = 2 ): string; overload; static;
    class procedure JsonToYaml( AJSON: TJSONValue; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2 ); overload; static;
    // YAML to JSON
    class function  YamlToJson( AYAML: string; AIndentation: TJsonIdentation = 0 ): string; overload; static;
    class function  YamlToJson( AYAML: TStrings; AIndentation: TJsonIdentation = 0 ): string; overload; static;
    class procedure YamlToJson( AYAML: TStrings; AOutStrings: TStrings; AIndentation: TJsonIdentation = 0 ); overload; static;
    class function  YamlToJsonValue( AYAML: string; AIndentation: TJsonIdentation = 0 ): TJSONValue; overload; static;
    class function  YamlToJsonValue( AYAML: TStrings; AIndentation: TJsonIdentation = 0 ): TJSONValue; overload; static;
  end;

implementation


class function  TYamlUtils.JsonToYaml( AJSON: string; AIndentation: TYamlIdentation = 2 ): string;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.ParseJSONValue( AJSON, False, True ) as TJSONObject;
  try
    Result := JsonToYaml( LJSONObject, AIndentation );
  finally
    LJSONObject.Free;
  end;
end;

class function  TYamlUtils.JsonToYaml( AJSON: TJSONValue; AIndentation: TYamlIdentation = 2 ): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    JsonToYaml( AJSON, LStrings, AIndentation );
    Result := LStrings.Text;
  finally
    LStrings.Free;
  end;
end;

class procedure TYamlUtils.JsonToYaml( AJSON: TJSONValue; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2 );
var
  LIndent: Integer;
begin
  LIndent := -1;
  AOutStrings.BeginUpdate;
  try
    AOutStrings.Clear;
    if (AJSON is TJSONObject) then
      InternalJsonObjToYaml( AJSON as TJSONObject, AOutStrings, AIndentation, LIndent )
    else if (AJSON is TJSONArray) then
      InternalJsonArrToYaml( AJSON as TJSONArray, AOutStrings, AIndentation, LIndent )
    else
      AOutStrings.Add( InternalJsonValueToYaml(AJSON) );
  finally
    AOutStrings.EndUpdate;
  end;
end;

class function  TYamlUtils.InternalJsonValueToYaml( AJSON: TJSONValue ): string;
begin
  Result := AJSON.Value;
  if (AJSON is TJSONFalse) then
    Result := 'false'
  else if (AJSON is TJSONTrue) then
    Result := 'true'
  else if (AJSON is TJSONNull) then
    Result := ''
  else if (AJSON is TJSONString) and not (AJSON is TJSONNumber) then
    begin
      if Result.Trim.IsEmpty then
        Result := '''''';
    end;
end;

class procedure TYamlUtils.InternalJsonObjToYaml( AJSON: TJSONObject; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False );
var
  I: Integer;
  LElement: TJSONPair;
  LName: string;
  LValue: TJSONValue;
  LSpaces: string;
begin
  Inc(AIndent);
  try
    for I := 0 to AJSON.Count - 1 do
      begin
        if (AFromArray) and (I = 0) then
          LSpaces := string.Create( ' ', (AIndent - 1) * AIndentation ) + '- '
        else
          LSpaces := string.Create( ' ', AIndent * AIndentation );
        LElement  := AJSON.Pairs[I];
        LName     := LElement.JsonString.Value;
        LValue    := LElement.JsonValue;
        // Check for object type
        if (LValue is TJSONObject) then
          begin
            AOutStrings.Add( LSpaces + LName + ':' );
            InternalJsonObjToYaml( LValue as TJSONObject, AOutStrings, AIndentation, AIndent );
          end
        else if (LValue is TJSONArray) then
          begin
            AOutStrings.Add( LSpaces + LName + ':' );
            InternalJsonArrToYaml( LValue as TJSONArray, AOutStrings, AIndentation, AIndent );
          end
        else
          AOutStrings.Add( LSpaces + LName + ': ' + InternalJsonValueToYaml(LValue) );
      end;
  finally
    Dec(AIndent);
  end;
end;

class procedure TYamlUtils.InternalJsonArrToYaml( AJSON: TJSONArray; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False );
var
  I: Integer;
  LValue: TJSONValue;
  LSpaces: string;
begin
  Inc(AIndent);
  try
    for I := 0 to AJSON.Count - 1 do
      begin
        if (AFromArray) and (I = 0) then
          LSpaces := string.Create( ' ', (AIndent - 1) * AIndentation ) + '- '
        else
          LSpaces := string.Create( ' ', AIndent * AIndentation );
        LValue  := AJSON.Items[I];
        // Check for object type
        if (LValue is TJSONObject) then
          InternalJsonObjToYaml( LValue as TJSONObject, AOutStrings, AIndentation, AIndent, True )
        // Check for array type
        else if (LValue is TJSONArray) then
          InternalJsonArrToYaml( LValue as TJSONArray, AOutStrings, AIndentation, AIndent, True )
        else
          AOutStrings.Add( LSpaces + '- ' + InternalJsonValueToYaml(LValue) );
      end;
  finally
    Dec(AIndent);
  end;
end;

class function  TYamlUtils.YamlToJson( AYAML: string; AIndentation: TJsonIdentation = 0 ): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    LStrings.Text := AYAML;
    Result := YamlToJson( LStrings, AIndentation );
  finally
    LStrings.Free;
  end;
end;

class function  TYamlUtils.YamlToJson( AYAML: TStrings; AIndentation: TJsonIdentation = 0 ): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    YamlToJson( AYAML, LStrings, AIndentation );
    Result := LStrings.Text;
  finally
    LStrings.Free;
  end;
end;

class function  TYamlUtils.YamlToJsonValue( AYAML: string; AIndentation: TJsonIdentation = 0 ): TJSONValue;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    Result := YamlToJsonValue( LStrings, AIndentation );
  finally
    LStrings.Free;
  end;
end;

class function  TYamlUtils.YamlToJsonValue( AYAML: TStrings; AIndentation: TJsonIdentation = 0 ): TJSONValue;
var
  LJSON: string;
begin
  LJSON := YamlToJson( AYAML, AIndentation );
  Result := TJSONObject.ParseJSONValue( LJSON, False, True );
end;

class procedure TYamlUtils.YamlToJson( AYAML: TStrings; AOutStrings: TStrings; AIndentation: TJsonIdentation = 0 );
var
  LLine: Integer;
  LCurrentLine: Integer;
  LIndentValue: Integer;
  LIsArrayElement: boolean;
begin
  LLine := -1;
  AOutStrings.BeginUpdate;
  try
    AOutStrings.Clear;
    // Get the first line and check what it is ...
    LCurrentLine    := -1;
    LIndentValue    := 0;
    LIsArrayElement := False;
    if InternalYamlNextText( AYAML, LCurrentLine, LIndentValue, LIsArrayElement ) = '' then
      AOutStrings.Add( '{}' )
    else
      begin
        if LIsArrayElement then
          InternalYamlArrToJson( AYAML, AOutStrings, AIndentation, 0, LLine, LIndentValue )
        else
          InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, 0, LLine, LIndentValue );
      end;
  finally
    AOutStrings.EndUpdate;
  end;
end;

class function  TYamlUtils.InternalGetNextToken( var S: string; Delimiters: string): string;
var
  idx: Integer;
begin
  if Delimiters = '' then
    begin
      Result := S;
      S := '';
    end
  else
    begin
      idx := FindDelimiter( Delimiters, S, 1 );
      if idx = 0 then
        begin
          Result := S;
          S := '';
        end
      else
        begin
          Result := S.Substring( 0, idx - 1 );
          S := S.Substring( idx, S.Length - idx );
        end;
    end;
end;

class procedure TYamlUtils.InternalYamlValueToJson( const AYAML: string; var AName, AValue: string );
var
  LElement: string;
begin
  LElement := AYAML.Trim;
  AName   := '"' + InternalGetNextToken(LElement, ':').Trim + '"';
  AValue  := LElement.Trim;
  if AValue.IsEmpty then
    AValue := 'null'
  else if AValue.ToLower.Equals('true') then
    AValue := 'true'
  else if AValue.ToLower.Equals('false') then
    AValue := 'false'
  else
    AValue := '"' + AValue + '"';
end;

class function  TYamlUtils.InternalYamlPrevLine( AYAML: TStrings; ACurrentLine: Integer ): Integer;
var
  LText: string;
begin
  Result  := ACurrentLine - 1;
  while (Result >= 0) do
    begin
      LText := AYAML[Result].Trim;
      if not (LText.IsEmpty or LText.StartsWith('#')) then
        Exit;
      Dec(Result);
    end;
end;

class function  TYamlUtils.InternalYamlNextText( AYAML: TStrings; var ACurrentLine, AIndentValue: Integer; var AIsArrayElement: boolean ): string;
var
  LLine: Integer;
  LFound: boolean;
  LText: string;
begin
  LLine           := ACurrentLine;
  LFound          := False;
  AIndentValue    := 0;
  AIsArrayElement := False;
  while (LLine < AYAML.Count - 1) and (not LFound) do
    begin
      Inc(LLine);
      LText := AYAML[LLine].Trim;
      if not (LText.IsEmpty or LText.StartsWith('#')) then
        begin
          LFound := True;
          // Check if it is an array
          AIsArrayElement := LText.StartsWith('- ');
          // Count indent spaces
          LText := AYAML[LLine];
          while (AIndentValue < LText.Length) and (LText.Substring(AIndentValue,1) = ' ') do
            Inc(AIndentValue);
          LText := AYAML[LLine].Trim;
          if AIsArrayElement then
            begin
              LText := LText.Substring(2);
              Inc(AIndentValue, 2);
            end;
        end;
    end;
  if not LFound then
    Exit('');
  ACurrentLine := LLine;
  Result := LText;
end;

class function  TYamlUtils.InternalYamlHasMoreText( AYAML: TStrings; ACurrentLine: Integer ): boolean;
var
  LCurrentLine: Integer;
  LIndentValue: Integer;
  LIsArrayElement: boolean;
begin
  LCurrentLine := ACurrentLine;
  rESULT := InternalYamlNextText( AYAML, LCurrentLine, LIndentValue, LIsArrayElement ) <> '';
end;

//class function  TYamlUtils.InternalYamlNextIsArrayElement( AYAML: TStrings; const ACurrentLine, ACurrentIndent: Integer ): boolean;
//var
//  LCurrentLine: Integer;
//  LIndentValue: Integer;
//  LIsArrayElement: boolean;
//begin
//  LCurrentLine  := ACurrentLine;
//  LIndentValue  := 0;
//  if InternalYamlNextText( AYAML, LCurrentLine, LIndentValue, LIsArrayElement ) <> '' then
//    Result := (LIsArrayElement) and (LIndentValue > ACurrentIndent);
//end;
//
//class function  TYamlUtils.InternalYamlNextIsObjectElement( AYAML: TStrings; const ACurrentLine, ACurrentIndent: Integer ): boolean;
//var
//  LCurrentLine: Integer;
//  LIndentValue: Integer;
//  LIsArrayElement: boolean;
//begin
//  LCurrentLine  := ACurrentLine;
//  LIndentValue  := 0;
//  Result := False;
//  if InternalYamlNextText( AYAML, LCurrentLine, LIndentValue, LIsArrayElement ) <> '' then
//    Result := (not LIsArrayElement) and (LIndentValue > ACurrentIndent);
//end;

class procedure TYamlUtils.InternalYamlNextProps( AYAML: TStrings; const ACurrentLine, ACurrentIndent: Integer; var AIsArray, AIsObject: boolean; var ALevel: Integer );
var
  LCurrentLine: Integer;
  LIndentValue: Integer;
  LIsArrayElement: boolean;
begin
  LCurrentLine  := ACurrentLine;
  LIndentValue  := 0;
  AIsArray      := False;
  AIsObject     := False;
  ALevel        := -1;
  if InternalYamlNextText( AYAML, LCurrentLine, LIndentValue, LIsArrayElement ) <> '' then
    begin
      if (LIndentValue < ACurrentIndent) then
        ALevel := -1
      else if (LIndentValue > ACurrentIndent) then
        ALevel := 1
      else
        ALevel := 0;
      AIsArray  := (LIsArrayElement);
      AIsObject := (not LIsArrayElement) and (LIndentValue > ACurrentIndent);
    end;
end;

//class function  TYamlUtils.InternalYamlNextIsSameLevel( AYAML: TStrings; const ACurrentLine, ACurrentIndent: Integer ): Integer;
//var
//  LCurrentLine: Integer;
//  LIndentValue: Integer;
//  LIsArrayElement: boolean;
//begin
//  LCurrentLine  := ACurrentLine;
//  LIndentValue  := 0;
//  Result := -1;
//  if InternalYamlNextText( AYAML, LCurrentLine, LIndentValue, LIsArrayElement ) <> '' then
//    begin
//      if (LIndentValue < ACurrentIndent) then
//        Result := -1
//      else if (LIndentValue > ACurrentIndent) then
//        Result := 1
//      else
//        Result := 0;
//    end;
//end;

class procedure TYamlUtils.InternalYamlObjToJson( AYAML, AOutStrings: TStrings; AIndentation: TJsonIdentation; AIndent: Integer; var ASrcLine: Integer; AYamlIndent: Integer; AFromArray: boolean = False );
var
  LSpaces: string;
  LBrackets: string;
  LLineIndent: Integer;
  LLineText: string;
  LIsArrayElement: boolean;
  LIsArrayStart: boolean;
  LIsObjectStart: boolean;
  LIsSameLevel: Integer;
  LNextIsArray: boolean;
  LElementName, LElementValue: string;
begin
  // Add element start
  Inc(AIndent);
  LBrackets := string.Create( ' ', (AIndent - 1) * AIndentation );
  LSpaces   := string.Create( ' ', (AIndent) * AIndentation );
  AOutStrings.Add( LBrackets + '{' );
  try
    // Initialization
    LLineIndent       := AYamlIndent;
    LNextIsArray      := False;
    while (ASrcLine < AYAML.Count - 1) and (LLineIndent = AYamlIndent) do
      begin
        // Get line to process
        LLineText := InternalYamlNextText( AYAML, ASrcLine, LLineIndent, LIsArrayElement );
        // Identify what the next line will be
        InternalYamlNextProps( AYAML, ASrcLine, LLineIndent, LIsArrayStart, LIsObjectStart, LIsSameLevel );
        // Process values
        InternalYamlValueToJson( LLineText, LElementName, LElementValue );

        if LLineIndent < AYamlIndent then
          begin
            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
            Exit;
          end
        else if (LLineIndent > AYamlIndent) then
          begin
            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
            if LNextIsArray then
              InternalYamlArrToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent )
            else
              InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent );
            LLineIndent       := AYamlIndent;
            InternalYamlNextProps( AYAML, ASrcLine, LLineIndent, LIsArrayStart, LIsObjectStart, LIsSameLevel );
          end
        else
          begin
            LNextIsArray  := LIsArrayStart;
            if LIsArrayStart and (not AFromArray) and (LIsSameLevel >= 0) then
              AOutStrings.Add( LSpaces + LElementName + ': ' )
            else if LIsObjectStart then
              AOutStrings.Add( LSpaces + LElementName + ': ' )
            else if LIsArrayElement and (not AFromArray) then
              AOutStrings.Add( LSpaces + LElementName + ', ' )
            else
              AOutStrings.Add( LSpaces + LElementName + ': ' + LElementValue + ', ' );
          end;
        if (LIsSameLevel < 0) or (LIsArrayStart and (LIsSameLevel = 0)) then
          Exit;
      end;
  finally
    // Add closure ...
    if AOutStrings[ AOutStrings.Count - 1 ].Equals( LBrackets + '{' ) then
      AOutStrings[ AOutStrings.Count - 1 ] := LBrackets + '{}'
    else
      begin
        if AOutStrings[ AOutStrings.Count - 1 ].EndsWith( ', ' ) then
          AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1].Remove( AOutStrings[AOutStrings.Count - 1].Length - 2 );
        AOutStrings.Add( LBrackets + '}' );
      end;
    if InternalYamlHasMoreText( AYAML, ASrcLine ) then
      AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1] + ', ';
  end;
end;

//class procedure TYamlUtils.InternalYamlObjToJson( AYAML, AOutStrings: TStrings; AIndentation: TJsonIdentation; AIndent: Integer; var ASrcLine: Integer; AYamlIndent: Integer; AFromArray: boolean = False );
//var
//  LSpaces: string;
//  LBrackets: string;
//  LLineText: string;
//  LLineIndent: Integer;
//  LIsArrayElement: boolean;
//  LIsArrayStart: boolean;
//  LIsObjectStart: boolean;
//  LNextIsArray: boolean;
//  LElementName, LElementValue: string;
//  LFirstElementDone: boolean;
//begin
//
//  // Add element start
//  Inc(AIndent);
//  LBrackets := string.Create( ' ', (AIndent - 1) * AIndentation );
//  LSpaces   := string.Create( ' ', (AIndent) * AIndentation );
//
//  // Add opening ...
//  AOutStrings.Add( LBrackets + '{' );
//  try
//    // Initialization
//    LLineIndent       := AYamlIndent;
//    LNextIsArray      := False;
//    LFirstElementDone := False;
//    while (ASrcLine < AYAML.Count - 1) and (LLineIndent = AYamlIndent) do
//      begin
//        LLineText := InternalYamlNextText( AYAML, ASrcLine, LLineIndent, LIsArrayElement );
//        // Is this an array starting ? (next yaml line starts with '- ')
//        LIsArrayStart   := InternalYamlNextIsArrayElement( AYAML, ASrcLine, LLineIndent );
//        LIsObjectStart  := InternalYamlNextIsObjectElement( AYAML, ASrcLine, LLineIndent );
//        // Get current element values
//        InternalYamlValueToJson( LLineText, LElementName, LElementValue );
//        if (LLineIndent < AYamlIndent) then
//          begin
//            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
//            Exit;
//          end
////        else if (LLineIndent = AYamlIndent) and AFromArray and LIsArrayElement and LFirstElementDone then
////          begin
////            Exit;
////          end
//        else if (LLineIndent > AYamlIndent) then
//          begin
//            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
////            if LNextIsArray then
////              InternalYamlArrToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent )
////            else
//              InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent );
//            LLineIndent       := AYamlIndent;
//          end
//        else
//          begin
//            LNextIsArray  := LIsArrayStart;
//            if LIsArrayStart and (not AFromArray) then
//              AOutStrings.Add( LSpaces + LElementName + ': ' )
//            else if LIsObjectStart then
//              AOutStrings.Add( LSpaces + LElementName + ': ' )
//            else if LIsArrayElement and (not AFromArray) then
//              AOutStrings.Add( LSpaces + LElementName + ', ' )
//            else
//              AOutStrings.Add( LSpaces + LElementName + ': ' + LElementValue + ', ' );
//            if (AFromArray and LIsArrayStart and LFirstElementDone) then
//              begin
//                ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
//                Dec(LLineIndent, 2);
//              end
//          end;
//
//        LFirstElementDone := True;
//      end;
//
//  finally
//    // Add closure ...
//    if AOutStrings[ AOutStrings.Count - 1 ].Equals( LBrackets + '{' ) then
//      AOutStrings[ AOutStrings.Count - 1 ] := LBrackets + '{}'
//    else
//      begin
//        if AOutStrings[ AOutStrings.Count - 1 ].EndsWith( ', ' ) then
//          AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1].Remove( AOutStrings[AOutStrings.Count - 1].Length - 2 );
//        AOutStrings.Add( LBrackets + '}' );
//      end;
//    if InternalYamlHasMoreText( AYAML, ASrcLine ) then
//      AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1] + ', ';
//  end;
//end;


class procedure TYamlUtils.InternalYamlArrToJson( AYAML, AOutStrings: TStrings; AIndentation: TJsonIdentation; AIndent: Integer; var ASrcLine: Integer; AYamlIndent: Integer );
var
  LSpaces: string;
  LBrackets: string;
  LLineText: string;
  LLineIndent: Integer;
  LIsArrayElement: boolean;
  LIsArrayStart: boolean;
  LIsObjectStart: boolean;
  LIsSameLevel: Integer;
  LElementName, LElementValue: string;
begin
  // Add element start
  Inc(AIndent);
  LBrackets := string.Create( ' ', (AIndent - 1) * AIndentation );
  LSpaces   := string.Create( ' ', (AIndent) * AIndentation );
  if AOutStrings.Count = 0 then
    AOutStrings.Add( LBrackets + '[ ' )
  else if AOutStrings[ AOutStrings.Count - 1 ].Trim.IsEmpty then
    AOutStrings[ AOutStrings.Count - 1 ] := LBrackets + '[ '
  else
    AOutStrings[ AOutStrings.Count - 1 ] := AOutStrings[ AOutStrings.Count - 1 ] + '[ ';
  try

    // Initialization
    LLineIndent       := AYamlIndent;
    LIsArrayElement := True;
    while (ASrcLine < AYAML.Count - 1) and (LLineIndent = AYamlIndent) do
      begin
        // Get line to process
        LLineText := InternalYamlNextText( AYAML, ASrcLine, LLineIndent, LIsArrayElement );
        // Identify what the next line will be
        InternalYamlNextProps( AYAML, ASrcLine, LLineIndent, LIsArrayStart, LIsObjectStart, LIsSameLevel );
        // Process values
        InternalYamlValueToJson( LLineText, LElementName, LElementValue );

        if (LLineIndent < AYamlIndent) then
          begin
            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
            Exit;
          end
        else if (LLineIndent > AYamlIndent) then
          begin
            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
            if LIsArrayStart then
              InternalYamlArrToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent )
            else
              InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent );
            LLineIndent       := AYamlIndent;
            InternalYamlNextProps( AYAML, ASrcLine, LLineIndent, LIsArrayStart, LIsObjectStart, LIsSameLevel );
          end
        else
          begin
            if (not LIsArrayStart) and (LIsSameLevel = 0) then
              begin
                ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
                InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent, True );
                LLineIndent       := AYamlIndent;
                InternalYamlNextProps( AYAML, ASrcLine, LLineIndent, LIsArrayStart, LIsObjectStart, LIsSameLevel );
              end
            else
              begin
                if LIsArrayStart or (LIsArrayElement and LElementValue.Equals('null')) then
                  AOutStrings.Add( LSpaces + LElementName + ', ' )
                else if LIsArrayStart then
                  AOutStrings.Add( LSpaces + LElementName + ': ' )
                else
                  AOutStrings.Add( LSpaces + LElementName + ': ' + LElementValue + ', ' );
              end;
          end;
        if (LIsSameLevel < 0) then
          Exit;
      end;

  finally
    // Add closure ...
    if AOutStrings[ AOutStrings.Count - 1 ].Equals( LBrackets + '[ ' ) then
      AOutStrings[ AOutStrings.Count - 1 ] := LBrackets + '[]'
    else
      begin
        if AOutStrings[ AOutStrings.Count - 1 ].EndsWith( ', ' ) then
          AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1].Remove( AOutStrings[AOutStrings.Count - 1].Length - 2 );
        if AOutStrings[ AOutStrings.Count - 1 ].EndsWith( '[ ' ) then
          begin
            AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1].Remove( AOutStrings[AOutStrings.Count - 1].Length - 2 );
            AOutStrings[ AOutStrings.Count - 1 ] := AOutStrings[ AOutStrings.Count - 1 ] + '[]';
          end
        else
          AOutStrings.Add( LBrackets + ']' );
      end;
    if InternalYamlHasMoreText( AYAML, ASrcLine ) then
      AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1] + ', ';
  end;
end;

//class procedure TYamlUtils.InternalYamlArrToJson( AYAML, AOutStrings: TStrings; AIndentation: TJsonIdentation; AIndent: Integer; var ASrcLine: Integer; AYamlIndent: Integer );
//var
//  LSpaces: string;
//  LBrackets: string;
//  LLineText: string;
//  LLineIndent: Integer;
//  LIsArrayElement: boolean;
//  LIsArrayStart: boolean;
//  LNextIsArray: boolean;
//  LIsSameLevel: Integer;
//  LElementName, LElementValue: string;
//begin
//  // Add element start
//  Inc(AIndent);
//  LBrackets := string.Create( ' ', (AIndent - 1) * AIndentation );
//  LSpaces   := string.Create( ' ', (AIndent) * AIndentation );
//
//  // Add opening ...
//  if AOutStrings.Count = 0 then
//    AOutStrings.Add( LBrackets + '[ ' )
//  else if AOutStrings[ AOutStrings.Count - 1 ].Trim.IsEmpty then
//    AOutStrings[ AOutStrings.Count - 1 ] := LBrackets + '[ '
//  else
//    AOutStrings[ AOutStrings.Count - 1 ] := AOutStrings[ AOutStrings.Count - 1 ] + '[ ';
//  try
//
//    // Initialization
//    LLineIndent     := AYamlIndent;
//    LIsArrayElement := True;
//    LNextIsArray    := False;
//    while (ASrcLine < AYAML.Count - 1) and (LLineIndent = AYamlIndent) and (LIsArrayElement)  do
//      begin
//        LLineText := InternalYamlNextText( AYAML, ASrcLine, LLineIndent, LIsArrayElement );
//        // Is this an array starting ? (next yaml line starts with '- ')
//        LIsArrayStart := InternalYamlNextIsArrayElement( AYAML, ASrcLine, LLineIndent );
//        LIsSameLevel  := InternalYamlNextIsSameLevel( AYAML, ASrcLine, LLineIndent );
//        // Get current element values
//        InternalYamlValueToJson( LLineText, LElementName, LElementValue );
//
//        if (LLineIndent < AYamlIndent) then
//          begin
//            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
//            Exit;
//          end
//        else if (LLineIndent > AYamlIndent) then
//          begin
//            ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
//            if LNextIsArray then
//              InternalYamlArrToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent )
//            else
//              InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent );
//            LLineIndent       := AYamlIndent;
//          end
//        else
//          begin
////            if (not LIsArrayStart) and (not LIsArrayElement) and (LIsSameLevel) then
//            if (not LIsArrayStart) and (LIsSameLevel = 0) then
//              begin
//                ASrcLine := InternalYamlPrevLine( AYAML, ASrcLine );
//                InternalYamlObjToJson( AYAML, AOutStrings, AIndentation, AIndent, ASrcLine, LLineIndent, True );
//                LLineIndent       := AYamlIndent;
//              end
//            else
//              begin
//                LNextIsArray  := LIsArrayStart;
//                if LIsArrayStart or (LIsArrayElement and LElementValue.Equals('null')) then
//                  AOutStrings.Add( LSpaces + LElementName + ', ' )
//                else if LIsArrayStart then
//                  AOutStrings.Add( LSpaces + LElementName + ': ' )
//                else
//                  AOutStrings.Add( LSpaces + LElementName + ': ' + LElementValue + ', ' );
//              end;
//          end;
//
//      end;
//
//  finally
//    // Add closure ...
//    if AOutStrings[ AOutStrings.Count - 1 ].Equals( LBrackets + '[ ' ) then
//      AOutStrings[ AOutStrings.Count - 1 ] := LBrackets + '[]'
//    else
//      begin
//        if AOutStrings[ AOutStrings.Count - 1 ].EndsWith( ', ' ) then
//          AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1].Remove( AOutStrings[AOutStrings.Count - 1].Length - 2 );
//        if AOutStrings[ AOutStrings.Count - 1 ].EndsWith( '[ ' ) then
//          begin
//            AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1].Remove( AOutStrings[AOutStrings.Count - 1].Length - 2 );
//            AOutStrings[ AOutStrings.Count - 1 ] := AOutStrings[ AOutStrings.Count - 1 ] + '[]';
//          end
//        else
//          AOutStrings.Add( LBrackets + ']' );
//      end;
//    if InternalYamlHasMoreText( AYAML, ASrcLine ) then
//      AOutStrings[AOutStrings.Count - 1] := AOutStrings[AOutStrings.Count - 1] + ', ';
//  end;
//
//end;

end.
