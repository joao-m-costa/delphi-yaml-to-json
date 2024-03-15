unit Costate.Utils.Yaml;

// YAML TOOLING
// ------------
// Convert YAML to JSON
// Convert JSON to YAML
//
// License: MIT License
// Creator: Joao Costa, costate@sapo.pt
// Last update: 15-03-2024
//
// YAML to JSON Capabilities
// -------------------------
// - Multiline values support, including folder modifiers (| and >), and chomp modifiers (+ and -)
// - Anchor / reference support (&anchor, *anchor)
// - Merge elements support (<<: *anchor)
// - Tags for explicit type indicators on values only (!!map, !!seq, !!str, !!null, !!bool, !!int, !!float, !!binary, !!timestamp)
// - Text escaping for JSON
// - Option to translate yes/no to booleans true/false
// - Option to prevent duplicated keys in maps per level
//
// JSON to YAML Capabilities
// -------------------------
// - Multiline values support, including folder modifiers (| and >), and chomp modifiers (+ and -)
// - Text unescaping for YAML
// - Option to translate booleans true/false to yes/no
//
// Useful references
// -----------------
// - https://onlineyamltools.com/convert-yaml-to-json
// - https://onlinejsontools.com/convert-json-to-yaml
// - https://yaml-multiline.info




interface

uses
  System.SysUtils, System.Classes, System.Character, System.DateUtils, System.JSON, System.JSON.Types, System.NetEncoding,
  System.Generics.Collections;

const
  EYamlCollectionItemError        = 'Yaml invalid collection item at line %d';
  EYamlInvalidArrayError          = 'Yaml invalid array at line %d';
  EYamlInvalidIndentError         = 'Yaml invalid identation an line %d';
  EYamlAnchorAliasNameError       = 'Yaml invalid alias/anchor name at line %d';
  EYamlAnchorDuplicateError       = 'Yaml duplicated anchor name at line %d';
  EYamlCollectionBlockError       = 'Yaml block modifiers can not be used for collection items at line %d';
  EYamlInvalidBlockError          = 'Yaml invalid block modifier at line %d';
  EYamlUnclosedLiteralError       = 'Yaml unclosed literal at line %d';
  EYamlKeyNameEmptyError          = 'Yaml empty key name at line %d';
  EYamlKeyNameMultilineError      = 'Yaml key names cannot be multiline at line %d';
  EYamlKeyNameAnchorAliasError    = 'Yaml aliases/anchors cannot be used for keys at line %d';
  EYamlKeyNameInvalidCharError    = 'Yaml invalid indicator "%s" for key al line %d';
  EYamlAnchorAliasValueError      = 'Yaml aliases for anchors cannot contain values at line %d';
  EYamlUnconsumedContentError     = 'Yaml unconsumed content at line %d';
  EYamlUnclosedArrayError         = 'Yaml unclosed array at line %d';
  EYamlCollectionInArrayError     = 'Yaml arrays cannot contain collection items at line %d';
  EYamlDoubleKeyError             = 'Yaml two keys for element at line %d';
  EYamlExpectedKeyError           = 'Yaml expected a key for element at line %d';
  EYamlDuplicatedKeyError         = 'Yaml duplicated key name at line %d';
  EYamlAnchorNotFoundError        = 'Yaml anchor "%s" not found for alias at line %d';
  EYamlAliasRecursiveError        = 'Yaml unsupported recursive alias "%s" found at line %d';
  EYamlMergeInArrayError          = 'Yaml merge indicator "<<" unsupported in arrays at line %d';
  EYamlMergeInCollectionError     = 'Yaml merge indicator "<<" unsupported in collections at line %d';
  EYamlMergeSingleValueError      = 'Yaml merge indicator "<<" unsupported for single values at line %d';
  EYamlMergeInvalidError          = 'Yaml invalid merge indicator "<<" without alias reference at line %d';
  EYamlInvalidTagError            = 'Yaml unreconized tag at line %d';
  EYamlInvalidValueForTagError    = 'Yaml invalid value type for tag at line %d';


type

  EYamlParsingException = class(Exception);

  TYamlUtils = record
  private
    const
      LLiteralReplacer: string = chr(11) + chr(11);
      LLiteralLineFeed: string = chr(14) + chr(14);
    const
      LTagMap: string   = '!!map';          // Dictionary map {key: value}
      LTagSeq: string   = '!!seq';          // Sequence (an array or collection)
      LTagStr: string   = '!!str';          // Normal string (no conversion)
      LTagNull: string  = '!!null';         // Null (must be null)
      LTagBool: string  = '!!bool';         // Boolean (true/false)
      LTagInt: string   = '!!int';          // Integer numeric
      LTagFloat: string = '!!float';        // Float numeric
      LTagBin: string   = '!!binary';       // Binary time (array of bytes)
      LTagTime: string  = '!!timestamp';    // Datetime type
    type
      TYamlTokenType  = (tokenKey, tokenValue);
      TBlockModifier  = (blockNone, blockFolded, blockLiteral);    // None, >, |
      TChompModifier  = (chompNone, chompClip, chompKeep);         // None, -, +
    type
      TYamlElement = record
        Key: string;
        Value: string;
        Indent: Integer;
        Literal: boolean;
        Alias: string;
        Anchor: string;
        LineNumber: Integer;
        Tag: string;
        class operator Initialize(out Dest: TYamlElement);
        class operator Assign(var Dest: TYamlElement; const [ref] Src: TYamlElement);
        procedure Clear();
      end;
    type
      TYamlElements = TList<TYamlElement>;
  public
    type
      TYamlIdentation = 2..8;
      TJsonIdentation = 0..8;
  private
    // Utilities section
    // -----------------
    // Escape YAML text to JSON
    class function  InternalStringEscape( const AText: string ): string; static;
    // Try convert a timestamp value to a datetime UTC
    class function  InternalTryStrToDateTime( const AText: string; var ADate: TDateTime; AFormatSettings: TFormatSettings ): boolean; static;
    // YAML to JSON section
    // --------------------
    // Read next text YAML line from strings
    class function  InternalYamlNextTextLine( AYAML: TStrings; var ARow, AIndent: Integer; AIgnoreBlanks: boolean = True; AIgnoreComments: boolean = True; AAutoTrim: boolean = True ): string; static;
    // Retrieve what next text will be
    class function  InternalYamlNextText( AYAML: TStrings; var ARow, AIndent: Integer; AText: string; AIgnoreBlanks: boolean = True; AIgnoreComments: boolean = True; AAutoTrim: boolean = True ): string; static;
    // Read next token from source, with multiline support
    class function  InternalYamlReadToken( AYAML: TStrings; var ARow, AIndent: Integer; var AText, ARemainer, AAlias, ATag: string; var ACollectionItem: Integer; var AIsLiteral: boolean; AInArray: boolean = False ): TYamlTokenType; static;
    // Find element containing an anchor by anchor name
    class function  InternalYamlFindAnchor( AElements: TYamlElements; AAnchorName: string ): Integer; static;
    // Resolve (pre-process) aliases to anchor values
    class procedure InternalYamlResolveAliases( AElements: TYamlElements ); static;
    // Merge (pre-process) aliases with anchor values
    class procedure InternalYamlResolveMerges( AElements: TYamlElements ); static;
    // Process an inline array from source
    class procedure InternalYamlProcessArray( AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: string; AYesNoBool: boolean; AAllowDuplicateKeys: boolean ); static;
    // Process a collection (array) from source
    class procedure InternalYamlProcessCollection( AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: string; AYesNoBool: boolean; AAllowDuplicateKeys: boolean ); static;
    // Process element pairs (key: value) from source
    class procedure InternalYamlProcessElements( AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: string; AYesNoBool: boolean; AAllowDuplicateKeys: boolean ); static;
    // Format a YAML value to JSON
    class function  InternalYamlProcessJsonValue( AValue: string; ALiteral: boolean; ATag: string; ALineNumber: Integer; AYesNoBool: boolean  ): string; static;
    // Convert the prepared TYamlElements list to JSON
    class procedure InternalYamlToJson( AElements: TYamlElements; AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: boolean ); static;
    // Entry point to parse YAML to JSON
    class procedure InternalYamlParse( AYAML, AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: boolean; AAllowDuplicateKeys: boolean ); static;
    // JSON to YAML section
    // --------------------
    // Process JSON object to YAML (a touple)
    class procedure InternalJsonObjToYaml( AJSON: TJSONObject; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False; AYesNoBool: boolean = False ); static;
    // Process JSON array to YAML
    class procedure InternalJsonArrToYaml( AJSON: TJSONArray; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False; AYesNoBool: boolean = False ); static;
    // Convert a value from JSON to YAML
    class function  InternalJsonValueToYaml( AJSON: TJSONValue; AIndent: Integer = 0; AYesNoBool: boolean = False ): TArray<string>; static;
  public
    // JSON to YAML
    class function  JsonToYaml( AJSON: string; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False ): string; overload; static;
    class procedure JsonToYaml( AJSON: TStrings; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False ); overload; static;
    class function  JsonToYaml( AJSON: TJSONValue; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False ): string; overload; static;
    class procedure JsonToYaml( AJSON: TJSONValue; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False ); overload; static;
    // YAML to JSON
    class procedure YamlToJson( AYAML: TStrings; AOutStrings: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ); overload; static;
    class function  YamlToJson( AYAML: string; AIndentation: TJsonIdentation = 2; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): string; overload; static;
    class function  YamlToJson( AYAML: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): string; overload; static;
    class function  YamlToJsonValue( AYAML: string; AIndentation: TJsonIdentation = 0; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): TJSONValue; overload; static;
    class function  YamlToJsonValue( AYAML: TStrings; AIndentation: TJsonIdentation = 0; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): TJSONValue; overload; static;
    // JSON tools
    class procedure JsonAsStrings( AJSON: TJSONValue; AOutStrings: TStrings; AIndentation: TJsonIdentation = 2 ); static;
    class function  JsonMinify( AJSON: string ): string; overload; static;
    class function  JsonMinify( AJSON: TStrings ): string; overload; static;
    class function  JsonMinify( AJSON: TJSONValue ): string; overload; static;
  end;


implementation


// Sub-type TYamlElement
// ---------------------

class operator TYamlUtils.TYamlElement.Initialize(out Dest: TYamlElement);
begin
  Dest.Key            := '';
  Dest.Value          := '';
  Dest.Indent         := -1;
  Dest.Literal        := False;
  Dest.Alias          := '';
  Dest.Anchor         := '';
  Dest.LineNumber     := 0;
  Dest.Tag            := '';
end;

class operator TYamlUtils.TYamlElement.Assign(var Dest: TYamlElement; const [ref] Src: TYamlElement);
begin
  Dest.Key            := Src.Key;
  Dest.Value          := Src.Value;
  Dest.Indent         := Src.Indent;
  Dest.Literal        := Src.Literal;
  Dest.Alias          := Src.Alias;
  Dest.Anchor         := Src.Anchor;
  Dest.LineNumber     := Src.LineNumber;
  Dest.Tag            := Src.Tag;
end;

procedure TYamlUtils.TYamlElement.Clear();
begin
  Key           := '';
  Value         := '';
  Indent        := -1;
  Literal       := False;
  Alias         := '';
  Anchor        := '';
  LineNumber    := 0;
  Tag           := '';
end;



// TYamlUtils static class (record)
// --------------------------------

// Escape string for Yaml to Json conversion
// If ALiteral is true, the source is enclosed with double-quotes ("value") and backslash will not be escaped
class function  TYamlUtils.InternalStringEscape( const AText: string ): string;
var
  LText: string;
begin
  LText := AText;
  LText := LText.Replace('\', '\\');                // backslash
  LText := LText.Replace('"', '\"');                // double quotes
  LText := LText.Replace(#8, '\b');                 // backspace
  LText := LText.Replace(#9, '\t');                 // tab
  LText := LText.Replace(#10, '\n');                // line feed
  LText := LText.Replace(#12, '\f');                // form feed
  LText := LText.Replace(#13, '\r');                // cariage return
  LText := LText.Replace(#$0085, '\u0085');         // new line (unicode)
  LText := LText.Replace(#$2028, '\u2028');         // line separator (unicode)
  LText := LText.Replace(#$2029, '\u2029');         // paragraph separator (unicode)
  LText := LText.Replace(LLiteralLineFeed, '\n');   // implicit line feed on literals
  Result := LText;
end;


// Try convert a timestamp value to a datetime UTC
class function  TYamlUtils.InternalTryStrToDateTime( const AText: string; var ADate: TDateTime; AFormatSettings: TFormatSettings ): boolean;
var
  LNumber: Integer;
  LText: string;
  LPos: Integer;
begin
  LText := AText;
  if TryStrToInt( LText.Substring(0,1), LNumber ) then
    begin
      LText := LText.Replace( '-', AFormatSettings.DateSeparator );
      LText := LText.Replace( '/', AFormatSettings.DateSeparator );
      LText := LText.Replace('t', 'T');
      LText := LText.Replace('z', 'Z');
      // Check if we need to invert year pos
      LPos := LText.IndexOf(AFormatSettings.DateSeparator);
      if LPos <= 2 then
        LText := LText.Substring( LPos + 4, 4) +  // Year
            LText.Substring( LPos, 1) +           // Sep
            LText.Substring( LPos + 1, 2) +       // Month
            LText.Substring( LPos, 1) +           // Sep
            LText.Substring(0, LPos) +            // Day
            LText.Substring( LPos + 8);           // Remaining
      // Try ISO8601 conversion, converting to UTC
      Result := System.DateUtils.TryISO8601ToDate( LText, ADate, True );
      // Of try the usual way
      if not Result then
        Result := TryStrToDateTime( LText, ADate, AFormatSettings );
    end
  else
    Result := False;
end;



// YAML to JSON section
// --------------------

// Read next text YAML line from strings
class function  TYamlUtils.InternalYamlNextTextLine( AYAML: TStrings; var ARow, AIndent: Integer; AIgnoreBlanks: boolean = True; AIgnoreComments: boolean = True; AAutoTrim: boolean = True ): string;
var
  LRow: Integer;
  LFound: boolean;
  LText: string;
begin
  LRow    := ARow;
  LFound  := False;
  while (LRow < AYAML.Count-1) and (not LFound) do
    begin
      Inc(LRow);
      LText := AYAML[LRow].TrimLeft;
      if not ( (LText.StartsWith('#') and AIgnoreComments) or (LText.Trim.IsEmpty and AIgnoreBlanks) ) then
        begin
          LFound  := True;
          // If line is blank (in a multiline element), keep same indent
          if not LText.Trim.IsEmpty then
            AIndent := AYAML[LRow].Length - LText.Length;
          LText   := AYAML[LRow];
        end;
    end;
  if not LFound then
    begin
      LText   := '';
      LRow    := -1;
      AIndent := -1;
    end;
  ARow    := LRow;
  if AAutoTrim then
    Result  := LText.Trim
  else
    Result  := LText;
end;


// Retrieve what next text will be
class function  TYamlUtils.InternalYamlNextText( AYAML: TStrings; var ARow, AIndent: Integer; AText: string; AIgnoreBlanks: boolean = True; AIgnoreComments: boolean = True; AAutoTrim: boolean = True ): string;
var
  LText: string;
begin
  if AText.IsEmpty then
    LText := InternalYamlNextTextLine( AYAML, ARow, AIndent, AIgnoreBlanks, AIgnoreComments, AAutoTrim )
  else
    LText := AText;
  Result := LText;
end;


// Read next token from source, with multiline support
class function  TYamlUtils.InternalYamlReadToken( AYAML: TStrings; var ARow, AIndent: Integer; var AText, ARemainer, AAlias, ATag: string; var ACollectionItem: Integer; var AIsLiteral: boolean; AInArray: boolean = False ): TYamlTokenType;
var
  LType: TYamlTokenType;
  LText: string;
  LRow: Integer;
  LIndent: Integer;
  LBlockModifier: TBlockModifier;
  LChompModifier: TChompModifier;
  LLiteral: string;
  LLiteralMask: string;
  LPos: Integer;
  LFound: boolean;
  LNextRow: Integer;
  LNextIndent: Integer;
  LNextText: string;
  LPrevRow: Integer;
  LPrevIndent: Integer;
  LLines: TStringList;
  I: Integer;
  LLinesCount: Integer;
  LLeftMargin: Integer;
  LMargin: Integer;
begin
  LType             := TYamlTokenType.tokenValue;
  LText             := AText;
  LRow              := ARow;
  LIndent           := AIndent;
  LPrevIndent       := AIndent;
  LPrevRow          := ARow;
  LBlockModifier    := blockNone;
  LChompModifier    := chompNone;
  LLiteral          := '';
  LLiteralMask      := '';
  LNextRow          := -1;
  LNextIndent       := -1;
  LNextText         := '';
  LLinesCount       := 0;
  ACollectionItem   := 0;
  AIsLiteral        := False;
  ARemainer         := '';
  AAlias            := '';
  ATag              := '';

  if LText.IsEmpty then
    LText := InternalYamlNextTextLine( AYAML, LRow, LIndent, True, True );

  // If reached EOF, exit
  if LRow < 0 then
    begin
      ARow    := -1;
      AIndent := -1;
      AText   := '';
      Exit(LType);
    end;

  // Check for tags
  if LText.ToLower.Trim.Equals(LTagMap) or LText.ToLower.StartsWith(LTagMap + ' ') then
    ATag := LTagMap
  else if LText.ToLower.Trim.Equals(LTagSeq) or LText.ToLower.StartsWith(LTagSeq + ' ') then
    ATag := LTagSeq
  else if LText.ToLower.Trim.Equals(LTagStr) or LText.ToLower.StartsWith(LTagStr + ' ') then
    ATag := LTagStr
  else if LText.ToLower.Trim.Equals(LTagNull) or LText.ToLower.StartsWith(LTagNull + ' ') then
    ATag := LTagNull
  else if LText.ToLower.Trim.Equals(LTagBool) or LText.ToLower.StartsWith(LTagBool + ' ') then
    ATag := LTagBool
  else if LText.ToLower.Trim.Equals(LTagInt) or LText.ToLower.StartsWith(LTagInt + ' ') then
    ATag := LTagInt
  else if LText.ToLower.Trim.Equals(LTagFloat) or LText.ToLower.StartsWith(LTagFloat + ' ') then
    ATag := LTagFloat
  else if LText.ToLower.Trim.Equals(LTagBin) or LText.ToLower.StartsWith(LTagBin + ' ') then
    ATag := LTagBin
  else if LText.ToLower.Trim.Equals(LTagTime) or LText.ToLower.StartsWith(LTagTime + ' ') then
    ATag := LTagTime
  else if LText.ToLower.StartsWith('!!') then
    raise EYamlParsingException.CreateFmt( EYamlInvalidTagError, [LRow + 1] );
  if not ATag.IsEmpty then
    begin
      LText := LText.Substring(ATag.Length).TrimLeft;
      if LText.IsEmpty then
        begin
          ARow        := LRow;
          AIndent     := LIndent;
          AText   := '';
          Exit(LType);
        end;
    end;

  // Check for inner array start/end/separator
  if LText.StartsWith('[') or ( AInArray and ( LText.StartsWith(']') or LText.StartsWith(',') ) ) then
    begin
      ARemainer := LText.Substring(1).Trim;
      AText     := LText.Substring(0,1);
      ARow      := LRow;
      AIndent   := LIndent;
      Exit(LType)
    end;

  // Check if it is a collection item
  if (LText.StartsWith('-')) and (not AInArray) then
    begin
      if not ( LText.StartsWith('- ') or LText.Equals('-') ) then
        raise EYamlParsingException.CreateFmt( EYamlCollectionItemError, [LRow + 1] );
      ACollectionItem := (LText.Substring(1).Length) - (LText.Substring(1).TrimLeft().Length) + 1;
      if ACollectionItem <= 0 then
        ACollectionItem := 2;
      LText     := LText.Substring(1).Trim;
    end;

  // Check for alias/anchor/references
  if LText.StartsWith('&') or LText.StartsWith('*') then
    begin
      if LText.Substring(1).StartsWith(' ') then
        raise EYamlParsingException.CreateFmt( EYamlAnchorAliasNameError, [LRow + 1] );
      if AInArray then
        LPos := LText.IndexOfAny( [' ', ','] )
      else
        LPos := LText.IndexOf(' ');
      if LPos >= 0 then
        begin
          AAlias  := LText.Substring(0, LPos).Trim;
          LText   := LText.Substring(LPos).Trim;
        end
      else
        begin
          AAlias  := LText;
          LText   := '';
        end;
      // Evaluate that the alias is a valid name
      if (not System.SysUtils.IsValidIdent(AAlias.Substring(1), False)) then
        raise EYamlParsingException.CreateFmt( EYamlAnchorAliasNameError, [LRow + 1] );
    end;

  // Check for block/folder modifiers, multiline related
  // If they are present, this must be a value
  if LText.StartsWith('|') or LText.StartsWith('>')  then
    begin
      if ACollectionItem > 0 then
        raise EYamlParsingException.CreateFmt( EYamlCollectionBlockError, [ LRow + 1 ] );
      if LText.StartsWith('|') then
        LBlockModifier := blockLiteral
      else
        LBlockModifier := blockFolded;
      LText := LText.Substring(1).Trim;
      if LText.StartsWith('+') or LText.StartsWith('-') then
        begin
          if LText.StartsWith('+') then
            LChompModifier := chompKeep
          else
            LChompModifier := chompClip;
          LText := LText.Substring(1).Trim;
        end;
    end;

  // Check for literals (starting with " or with ' )
  if LText.StartsWith('"') then
    begin
      LLiteral      := '"';
      LLiteralMask  := '\"';
    end
  else if LText.StartsWith('''') then
    begin
      LLiteral      := '''';
      LLiteralMask  := '''''';
    end;

  // Read the token, check if multilines are actually there, to avoid multiline strings processing if not needed
  // When not found, multilines are present so we will have to keep reading
  LFound := False;
  // Is it literal
  if not LLiteral.IsEmpty then
    begin
      LText := LText.Substring(1).Replace(LLiteralMask, LLiteralReplacer);
      LPos  := LText.IndexOf(LLiteral);
      // Closure found inline
      if LPos >= 0 then
        begin
          LFound    := True;
          ARemainer := LText.Substring(LPos + 1).Replace(LLiteralReplacer, LLiteralMask).Trim;
          LText     := LText.Substring(0, LPos).Replace(LLiteralReplacer, LLiteral);
        end;
    end
  else
    begin
      // Check for inline array element termination
      if AInArray then
        begin
          LPos := LText.IndexOfAny( [',', ']'] );
          if LPos >= 0 then
            begin
              LFound := True;
              ARemainer := LText.Substring(LPos) + ARemainer;
              LText     := LText.Substring(0, LPos);
            end;
        end;
      // Check for inline key: value termination
      LPos := LText.IndexOf( ': ' );
      if (LPos < 0) and LText.EndsWith(':') then
        LPos := LText.Length - 1;
      if LPos >= 0 then
        begin
          LFound := True;
          ARemainer := LText.Substring(LPos) + ARemainer;
          LText     := LText.Substring(0, LPos);
        end;
      // Still not found, so take a look at next row and evaluate termination
      if not LFound then
        begin
          LNextRow    := LRow;
          LNextIndent := LIndent;
          LNextText   := InternalYamlNextText( AYAML, LNextRow, LNextIndent, ARemainer, True, True );
          // EOF
          if LNextRow < 0 then
            LFound := True
          // Collection item failure
          else if (ACollectionItem > 0) and (LNextRow = LRow) then
            raise EYamlParsingException.CreateFmt( EYamlCollectionItemError, [LRow + 1] )
          // Another collection item at the same level
          else if (ACollectionItem > 0) and (LNextIndent = LIndent) and (LNextText.StartsWith('- ') or LNextText.Equals('-')) then
            LFound := True
          // A collection is starting
          else if (ACollectionItem <= 0) and (LNextIndent >= LIndent) and (LNextText.StartsWith('- ') or LNextText.Equals('-')) then
            LFound := True
          // New element or outdenting
          else if (LNextIndent <= AIndent) then
            LFound := True
          // Indenting new key
          else if (LNextIndent > AIndent) and (LNextText.EndsWith(':') or (LNextText.IndexOf(': ') >= 0)) then
            LFound := True;
          // In case multiline starts at next row
          if (LRow > LPrevRow) and (LPrevIndent < LIndent) then
            LIndent := LPrevIndent;
        end;
    end;

  // Not found, go for multilines
  if (not LFound) and (LRow >= 0) and (LRow < AYAML.Count - 1) then
    begin
      LNextRow    := LRow;
      LNextIndent := AIndent;
      LLines := TStringList.Create;
      try
        if not LText.IsEmpty then
          LLines.Add(LText);
        while (not LFound) and (LNextRow >= 0) do
          begin
            LText := InternalYamlNextTextLine( AYAML, LNextRow, LNextIndent, False, (not LLiteral.IsEmpty), False );
            // Literal text, must find text closure
            if (not LLiteral.IsEmpty) then
              begin
                LText := LText.Replace(LLiteralMask, LLiteralReplacer);
                LPos := LText.IndexOf(LLiteral);
                if LPos >= 0 then
                  begin
                    LFound := True;
                    ARemainer := LText.Substring(LPos+1).Replace(LLiteralReplacer, LLiteralMask).Trim;
                    LLines.Add(LText.Substring(0, LPos));
                  end
                else
                  LLines.Add(LText);
                LRow := LNextRow;
              end
            // Reached EOF
            else if (LNextRow < 0) then
              LFound := True
            else
              begin
                // Outdenting or new element
                if (LNextIndent <= LIndent) and (not AInArray) and (not LText.Trim.IsEmpty) then
                  LFound := True
                // Another collection item at the same level
                else if (ACollectionItem > 0) and (LNextIndent = LIndent) and (LNextText.StartsWith('- ') or LNextText.Equals('-')) then
                  LFound := True
                // Collection item starting
                else if (ACollectionItem <= 0) and (not AInArray) and (LNextIndent >= LIndent) and (LNextText.StartsWith('- ') or LNextText.Equals('-')) then
                  LFound := True
                // Splitted line ending
                else
                  begin
                    LPos := -1;
                    if AInArray then
                      LPos := LText.IndexOfAny([',', ']', '[']);
                    if LPos < 0 then
                      LPos := LText.IndexOf(': ');
                    if (LPos < 0) and LText.EndsWith(':') then
                      LPos := LText.Length - 1;
                    if LPos >= 0 then
                      begin
                        LFound := True;
                        ARemainer := LText.Substring(LPos).Trim;
                        LLines.Add(LText.Substring(0, LPos));
                      end;
                  end;
                // Not found inline, add new line
                if (not LFound) then
                  begin
                    LLines.Add(LText);
                    LRow := LNextRow;
                  end;
              end;
          end;
        // All lines were read.
        // Process them according literal/scallar/chomp options
        LLinesCount := LLines.Count;
        // Top empty lines are only kept if literal is " or we have a folder modified
        if (LFound) and (LBlockModifier = blockNone) and (not LLiteral.Equals('"')) then
          begin
            while (LLines.Count > 0) and (LLines[0].Trim.IsEmpty) do
              LLines.Delete(0);
          end;
        // Bottom empty lines are only kept if literal is " or chomp modifier is +
        if (LFound) and (LChompModifier <> chompKeep) and (not LLiteral.Equals('"')) then
          begin
            I := LLines.Count - 1;
            while (I >= 0) and (LLines[I].Trim.IsEmpty) do
              begin
                LLines.Delete(I);
                Dec(I);
              end;
          end;
        // Compute multiline left alignment
        if (LFound) then
          begin
            LLeftMargin := -1;
            for I := 1 to LLines.Count - 1 do
              begin
                if not LLines[I].IsEmpty then
                  begin
                    LText := LLines[I];
                    LMargin := LLines[I].Length - LLines[I].TrimLeft.Length;
                    if (LLeftMargin <= 0) or (LMargin < LLeftMargin) then
                      LLeftMargin := LMargin;
                  end;
              end;
            if LLines.Count > 0 then
              LLines[0] := string.Create(' ', LLeftMargin) + LLines[0];
            for I := 0 to LLines.Count - 1 do
              LLines[I] := LLines[I].Substring(LLeftMargin);
          end;
        // Convert it back to a single text for json
        if (LFound) then
          begin
            LText := '';
            for I := 0 to LLines.Count - 1 do
              begin
                if LLines[I].Trim.IsEmpty then
                  LText := LText + LLiteralLineFeed
                else if LBlockModifier = blockLiteral then
                  LText := LText + LLines[I] + LLiteralLineFeed
                else if LLines[I].StartsWith(' ') and (LBlockModifier <> blockNone) then
                  begin
                    if LText.IsEmpty then
                      LText := LText + LLines[I] + LLiteralLineFeed
                    else if (I > 0) and (LLines[I - 1].Trim.IsEmpty or LLines[I - 1].StartsWith(' ')) then
                      LText := LText + LLines[I] + LLiteralLineFeed
                    else
                      LText := LText + LLiteralLineFeed + LLines[I] + LLiteralLineFeed;
                  end
                else
                  begin
                    if not (LText.IsEmpty or LText.EndsWith(LLiteralLineFeed) or LText.EndsWith(' ')) then
                      LText := LText + ' ';
                    if (LBlockModifier = blockNone) then
                      LText := LText + LLines[I].Trim()
                    else
                      LText := LText + LLines[I];
                  end;
              end;
            if (LBlockModifier = blockFolded) and (LChompModifier <> chompClip) then
              LText := LText + LLiteralLineFeed;
            if LText.EndsWith(LLiteralLineFeed) and (LChompModifier = chompClip) then
              LText := LText.Substring( 0, LText.Length - LLiteralLineFeed.Length );
            if (not LLiteral.IsEmpty) then
              LText := LText.Replace(LLiteralReplacer, LLiteral);
          end;
      finally
        FreeAndNil(LLines);
      end;
    end;

  // If unclosed literal element, raise
  if (not LFound) and (not LLiteral.IsEmpty) then
    raise EYamlParsingException.CreateFmt( EYamlUnclosedLiteralError, [ LRow + 1 ] );

  // Check for key type
  if (ARemainer = ':') or ARemainer.StartsWith(': ') or (AInArray and ARemainer.StartsWith(':,')) then
    begin
      LType := TYamlTokenType.tokenKey;
      ARemainer := ARemainer.Substring(1).Trim;
      // Keys cannot be empty
      if LText.IsEmpty then
        raise EYamlParsingException.CreateFmt( EYamlKeyNameEmptyError, [ LRow + 1 ] );
      // Keys cannot be multiline
      if LLinesCount > 1 then
        raise EYamlParsingException.CreateFmt( EYamlKeyNameMultilineError, [ LRow + 1 ] );
      // Keys cannot have aliases/anchors
      if not AAlias.IsEmpty then
        raise EYamlParsingException.CreateFmt( EYamlKeyNameAnchorAliasError, [ LRow + 1 ] );
      // Check accepted initial chars for keys
      if System.SysUtils.CharInSet( LText.Chars[0], ['[', ',', ']', '-', '&', '*', '|', '>', '+'] ) then
        raise EYamlParsingException.CreateFmt( EYamlKeyNameInvalidCharError, [ LText.Substring(0,1), LRow + 1 ] );
    end;

  // Check for anchor reference with value
  if (not AAlias.IsEmpty) and (AAlias.StartsWith('*')) and (not LText.IsEmpty) then
    raise EYamlParsingException.CreateFmt( EYamlAnchorAliasValueError, [ LRow + 1 ] );

  AIsLiteral  := not LLiteral.IsEmpty;
  ARow        := LRow;
  AIndent     := LIndent;
  if AIsLiteral then
    AText     := InternalStringEscape( LText )
  else
    AText     := InternalStringEscape( LText.Trim( [' '] ) );
  Result      := LType;
end;


// Find element containing an anchor by anchor name
class function  TYamlUtils.InternalYamlFindAnchor( AElements: TYamlElements; AAnchorName: string ): Integer;
var
  I: Integer;
begin
  if not AAnchorName.IsEmpty then
    for I := 0 to AElements.Count - 1 do
      if AElements[I].Anchor.Equals(AAnchorName) then
        Exit( I );
  Result := -1;
end;


// Resolve (pre-process) aliases to anchor values
class procedure TYamlUtils.InternalYamlResolveAliases( AElements: TYamlElements );
var
  I: Integer;
  LAnchor: Integer;
  LAlias: Integer;
  LAliasName: string;
  LAliasElement: TYamlElement;
  LAnchorElement: TYamlElement;
  LElement: TYamlElement;
  LDone: boolean;
  LRefIndent: Integer;
  LSubElements: TYamlElements;
begin
  if AElements.Count = 0 then
    Exit;
  LDone := False;
  while not LDone do
    begin
      LAlias      := -1;
      LAliasName  := '';
      I := 0;
      while (LAliasName.IsEmpty) and (I < AElements.Count) do
        begin
          if (not AElements[I].Alias.IsEmpty) and (not AElements[I].Key.Equals('<<')) then
            begin
              LAlias        := I;
              LAliasName    := AElements[I].Alias;
              LAliasElement := AElements[I];
            end
          else
            Inc(I);
        end;
      if LAliasName.IsEmpty then
        LDone := True
      else
        begin
          LAliasElement.Alias := '';
          AElements[LAlias] := LAliasElement;
          // Find the enchor
          LAnchor := InternalYamlFindAnchor( AElements, LAliasName );
          if LAnchor < 0 then
            raise EYamlParsingException.CreateFmt( EYamlAnchorNotFoundError, [LAliasName, LAliasElement.LineNumber] );
          LAnchorElement := AElements[LAnchor];
          // Is it a single value reference ?
          if not LAnchorElement.Value.IsEmpty then
            begin
              LAliasElement.Value   := LAnchorElement.Value;
              LAliasElement.Literal := LAnchorElement.Literal;
              LAliasElement.Tag     := LAnchorElement.Tag;
              AElements[LAlias] := LAliasElement;
            end
          // Is it a subchain reference ?
          else
            begin
              LRefIndent := LAnchorElement.Indent;
              LSubElements := TYamlElements.Create;
              try
                I := LAnchor + 1;
                while (I > 0) and (I < AElements.Count) do
                  begin
                    if AElements[I].Indent > LRefIndent then
                      begin
                        if (AElements[I].Alias = LAliasName) then
                          raise EYamlParsingException.CreateFmt( EYamlAliasRecursiveError, [LAliasName, AElements[I].LineNumber] );
                        LElement := AElements[I];
                        LElement.Indent := LElement.Indent - LRefIndent + LAliasElement.Indent;
                        LSubElements.Add( LElement );
                        Inc(I);
                      end
                    else
                      I := -1;
                  end;
                if LSubElements.Count > 0 then
                  AElements.InsertRange( LAlias + 1, LSubElements );
              finally
                FreeAndNil(LSubElements);
              end;
            end;
        end;
    end;
end;



// Merge (pre-process) aliases with anchor values
class procedure TYamlUtils.InternalYamlResolveMerges( AElements: TYamlElements );
var
  I, Z: Integer;
  LAnchor: Integer;
  LAlias: Integer;
  LAliasName: string;
  LAliasElement: TYamlElement;
  LAnchorElement: TYamlElement;
  LDone: boolean;
  LElement: TYamlElement;
  LRefIndent: Integer;
  LBaseIndent: Integer;
  LRefParent: Integer;
  LSubElements: TYamlElements;
  LAnchorElements: TYamlElements;
  LMergeElements: TYamlElements;
  LIndex: Integer;
  LIndent: Integer;

  function __FindExistingElement( AList: TYamlElements; AElement: TYamlElement ): Integer;
  var
    X: Integer;
  begin
    for X := 0 to AList.Count - 1 do
      begin
        if (AList[X].Indent = AElement.Indent) and
          ( (not AElement.Key.IsEmpty and AElement.Key.Equals(AList[X].Key)) or
          (AElement.Key.IsEmpty and AElement.Value.Equals(AList[X].Value)) ) then
          Exit(X);
      end;
    Result := -1;
  end;

begin
  if AElements.Count = 0 then
    Exit;
  LSubElements    := nil;
  LMergeElements  := nil;
  try
    LSubElements    := TYamlElements.Create;
    LAnchorElements := TYamlElements.Create;
    LMergeElements  := TYamlElements.Create;
    LDone := False;
    while not LDone do
      begin
        LAlias      := -1;
        LAliasName  := '';
        I := 0;
        while (LAliasName.IsEmpty) and (I < AElements.Count) do
          begin
            if (not AElements[I].Alias.IsEmpty) and (AElements[I].Key.Equals('<<')) then
              begin
                LAlias        := I;
                LAliasName    := AElements[I].Alias;
                LAliasElement := AElements[I];
              end
            else
              Inc(I);
          end;
        if LAliasName.IsEmpty then
          LDone := True
        else
          begin
            // Find the enchor
            LAnchor := InternalYamlFindAnchor( AElements, LAliasName );
            if LAnchor < 0 then
              raise EYamlParsingException.CreateFmt( EYamlAnchorNotFoundError, [LAliasName, LAliasElement.LineNumber] );
            LAnchorElement := AElements[LAnchor];
            // Is it a single value reference ?
            if not LAnchorElement.Value.IsEmpty then
              raise EYamlParsingException.CreateFmt( EYamlMergeSingleValueError, [LAliasName, LAliasElement.LineNumber] );
            // Find the relative root
            LRefIndent := LAliasElement.Indent;
            LBaseIndent := 0;
            LRefParent := -1;
            I := LAlias - 1;
            while (I >= 0) and (LRefParent = -1) do
              begin
                 if AElements[I].Indent < LRefIndent then
                   begin
                     LRefParent  := I;
                     LBaseIndent := AElements[I].Indent;
                   end
                 else
                   Dec(I);
              end;
            // Get the anchor elements
            LRefIndent := LAnchorElement.Indent;
            LAnchorElements.Clear;
            I := LAnchor + 1;
            while (I > 0) and (I < AElements.Count) do
              begin
                if AElements[I].Indent > LRefIndent then
                  begin
                    if (AElements[I].Alias = LAliasName) then
                      raise EYamlParsingException.CreateFmt( EYamlAliasRecursiveError, [LAliasName, AElements[I].LineNumber] );
                    LElement := AElements[I];
                    LElement.Indent := LElement.Indent - LRefIndent + LBaseIndent;
                    LAnchorElements.Add( LElement );
                    Inc(I);
                  end
                else
                  I := -1;
              end;
            // Read existing elements to merge with and removed them from chain (they will be reinserted after merging)
            LMergeElements.Clear;
            LRefIndent := LAliasElement.Indent;
            I := LRefParent + 1;
            while (I > 0) and (I < AElements.Count) do
              begin
                if AElements[I].Indent >= LRefIndent then
                  begin
                    if not (AElements[I].Alias = LAliasName) then
                      begin
                        LElement := AElements[I];
                        LMergeElements.Add( LElement );
                      end;
                    AElements.Delete(I);
                  end
                else
                  I := -1;
              end;
            // Remove existing arrays/collections from anchor elements as the do not merge
            for I := 0 to LMergeElements.Count - 1 do
              begin
                LElement := LMergeElements[I];
                if not LElement.Key.IsEmpty then
                  begin
                    LIndex := __FindExistingElement( LAnchorElements, LElement );
                    if (LIndex >= 0) and (LIndex < LAnchorElements.Count - 1) and (LAnchorElements[LIndex + 1].Key.IsEmpty) and (LAnchorElements[LIndex + 1].Value.Equals('['))  then
                      begin
                        // Remove the array chain
                        Z := LIndex + 1;
                        LAnchorElement := LAnchorElements[Z];
                        LIndent := LAnchorElement.Indent;
                        while (Z >= 0) and (LAnchorElements.Count > Z) do
                          begin
                            LAnchorElements.Delete(Z);
                            if (LAnchorElement.Indent = LIndent) and (LAnchorElement.Key.IsEmpty) and (LAnchorElement.Value.Equals(']')) then
                              Z := -1
                            else if (LAnchorElements.Count > Z) then
                              LAnchorElement := LAnchorElements[Z];
                          end;
                        LAnchorElements.Delete(LIndex);
                      end;
                  end;
              end;
            // Do the merge
            LSubElements.Clear;
            while LAnchorElements.Count > 0 do
              begin
                LAnchorElement := LAnchorElements[0];
                LIndex := __FindExistingElement( LMergeElements, LAnchorElement );
                if LIndex >= 0 then
                  begin
                    LAnchorElement.Key      := LMergeElements[LIndex].Key;
                    LAnchorElement.Value    := LMergeElements[LIndex].Value;
                    LAnchorElement.Literal  := LMergeElements[LIndex].Literal;
                    LAnchorElement.Tag      := LMergeElements[LIndex].Tag;
                    LMergeElements.Delete(LIndex);
                  end;
                LSubElements.Add(LAnchorElement);
                LAnchorElements.Delete(0);
                // Check for orphans
                if LMergeElements.Count > 0 then
                  begin
                    LAliasElement  := LMergeElements[0];
                    LIndex := __FindExistingElement( LAnchorElements, LAliasElement );
                    while (LIndex < 0) and (LMergeElements.Count > 0) do
                      begin
                        LSubElements.Add(LAliasElement);
                        LMergeElements.Delete(0);
                        if LMergeElements.Count > 0 then
                          begin
                            LAliasElement  := LMergeElements[0];
                            LIndex := __FindExistingElement( LAnchorElements, LAliasElement );
                          end;
                      end;
                  end;
              end;
            if LSubElements.Count > 0 then
              AElements.InsertRange( LRefParent + 1, LSubElements );
          end;
      end;
  finally
    FreeAndNil(LAnchorElements);
    FreeAndNil(LMergeElements);
    FreeAndNil(LSubElements);
  end;
end;


// Process an inline array from source
class procedure TYamlUtils.InternalYamlProcessArray( AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: string; AYesNoBool: boolean; AAllowDuplicateKeys: boolean );
var
  LType: TYamlTokenType;
  LElement: TYamlElement;
  XElement: TYamlElement;
  LElementIndent: Integer;
  LRow: Integer;
  LCurrRow: Integer;
  LIndent: Integer;
  LText: string;
  LRemainer: string;
  LAlias: string;
  LTag: string;
  LCollectionItem: Integer;
  LIsLiteral: boolean;
  LLastSeparator: string;
  LDone: boolean;
  LClosed: boolean;
  LNextRow: Integer;
  LNextIndent: Integer;
  LNextText: string;
begin
  LElementIndent    := 0;
  LRow              := ARow;
  LCurrRow          := ARow;
  LIndent           := AIndent;
  LText             := AText;
  LRemainer         := AText;
  LAlias            := '';
  LCollectionItem   := 0;
  LIsLiteral        := False;
  LLastSeparator    := '[';
  LDone             := False;
  LClosed           := False;
  LNextRow          := -1;
  LNextIndent       := -1;
  LNextText         := '';

  // Get last element in elements list, if it exists, and indent from it
  if AElements.Count > 0 then
    begin
      if (AElements.Last.Value = ']') and (AElements.Last.Key.IsEmpty()) then
        LElementIndent  := AElements.Last.Indent
      else
        LElementIndent  := AElements.Last.Indent + 1;
    end;

  // Absorbe the first [ text and open the array
  InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, True );
  if not LText.Equals('[') then
    raise EYamlParsingException.CreateFmt( EYamlInvalidArrayError, [LRow + 1] );
  LLastSeparator := '[';
  LElement.Indent     := LElementIndent;
  LElement.LineNumber := LRow + 1;
  LElement.Value      := '[';
  AElements.Add(LElement);
  LElement.Clear;

  while not LDone do
    begin

      // Did we reach EOF ?
      if LRow < 0 then
        LDone := True
      else
        begin

          LElement.Indent := LElementIndent;
          LText           := LRemainer;

          // Check what will be next, in case we need to jump somewhere
          LCurrRow    := LRow;
          LNextRow    := LRow;
          LNextIndent := LIndent;
          LNextText   := InternalYamlNextText( AYAML, LNextRow, LNextIndent, LRemainer, True, True );

          // We have an array inside an array
          if LNextText.StartsWith('[') then
            begin
              InternalYamlProcessArray( AYAML, AElements, LRow, LNextIndent, LRemainer, AYesNoBool, AAllowDuplicateKeys );
              LLastSeparator := ']';
            end
          else
            begin
              LType := InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, True );
              // Array is being closed, absorve it
              if LText = ']' then
                begin
                  LElement.LineNumber := LRow + 1;
                  if (LLastSeparator = ',') and not LNextText.StartsWith('[') then
                    begin
                      LElement.Value := 'null';
                      AElements.Add(LElement);
                    end;
                  LElement.Value := ']';
                  AElements.Add(LElement);
                  LElement.Clear;
                  LClosed := True;
                  LDone := True;
                  LLastSeparator := ']';
                end
              // Array element split, absorve it
              else if LText = ',' then
                begin
                  if (LLastSeparator = ',') or (LLastSeparator = '[') then
                    begin
                      LElement.Value := 'null';
                      LElement.LineNumber := LRow + 1;
                      AElements.Add(LElement);
                      LElement.Clear;
                    end;
                  LLastSeparator := ',';
                end
              // Go for the data
              else
                begin
                  LLastSeparator := '';
                  // Inline arrays do not support collection items
                  if ( (LCollectionItem > 0) or LText.StartsWith('- ') or LText.Equals('-') ) and (not LIsLiteral) then
                    raise EYamlParsingException.CreateFmt( EYamlCollectionInArrayError, [LRow + 1] );
                  if (LType = TYamlTokenType.tokenKey) then
                    begin
                      if LText.Equals('<<') then
                        raise EYamlParsingException.CreateFmt( EYamlMergeInArrayError, [LRow + 1] );
                      LElement.Key := LText;
                      LText := LRemainer;
                      LType := InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, True );
                      // Inline element with two keys
                      if LType = TYamlTokenType.tokenKey then
                        raise EYamlParsingException.CreateFmt( EYamlDoubleKeyError, [LRow + 1] );
                      // Inline arrays do not support collection items
                      if ( (LCollectionItem > 0) or LText.StartsWith('- ') or LText.Equals('-') ) and (not LIsLiteral) then
                        raise EYamlParsingException.CreateFmt( EYamlCollectionInArrayError, [LRow + 1] );
                      if LText = ',' then
                        begin
                          LRemainer := LText + LRemainer;
                          LText := '';
                        end;
                    end;
                  LElement.Literal  := LIsLiteral;
                  LElement.Tag      := LTag;
                  if not LAlias.IsEmpty then
                    begin
                      if LAlias.StartsWith('*') then
                        LElement.Alias    := LAlias.Substring(1)
                      else
                        begin
                          LElement.Anchor   := LAlias.Substring(1);
                          // Avoid duplicated anchor names
                          if InternalYamlFindAnchor( AElements, LElement.Anchor ) >= 0 then
                            raise EYamlParsingException.CreateFmt( EYamlAnchorDuplicateError, [LRow + 1] );
                        end;
                    end;
                  if not LElement.Key.IsEmpty then
                    begin
                      XElement.Indent     := LElementIndent + 1;
                      XElement.LineNumber := LRow + 1;
                      XElement.Value      := '{';
                      AElements.Add(XElement);
                      LElement.Indent     := LElementIndent + 1;
                    end;
                  if LText.IsEmpty then
                    LElement.Value := 'null'
                  else
                    LElement.Value := LText;
                  LElement.LineNumber := LRow + 1;
                  AElements.Add(LElement);
                  if not LElement.Key.IsEmpty then
                    begin
                      XElement.Indent     := LElementIndent + 1;
                      XElement.LineNumber := LRow + 1;
                      XElement.Value      := '}';
                      AElements.Add(XElement);
                    end;
                  LElement.Clear;
                end;
            end;
        end;

    end;

  if not LClosed then
    raise EYamlParsingException.CreateFmt( EYamlUnclosedArrayError, [LRow + 1] );
  ARow  := LCurrRow;
  AText := LRemainer;
end;


// Process a collection (array) from source
class procedure TYamlUtils.InternalYamlProcessCollection( AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: string; AYesNoBool: boolean; AAllowDuplicateKeys: boolean );
var
  LType: TYamlTokenType;
  LElement: TYamlElement;
  LElementIndent: Integer;
  LDone: boolean;
  LRow: Integer;
  LCurrRow: Integer;
  LIndent: Integer;
  LText: string;
  LRemainer: string;
  LNextRow: Integer;
  LNextIndent: Integer;
  LNextText: string;
  LItemsIndent: Integer;
  LAlias: string;
  LTag: string;
  LPrevRemainer: string;
  LIsLiteral: boolean;
  LCollectionItem: Integer;
begin
  LElementIndent    := 0;
  LDone             := False;
  LRow              := ARow;
  LCurrRow          := ARow;
  LIndent           := AIndent;
  LText             := AText;
  LRemainer         := AText;
  LNextRow          := 0;
  LNextIndent       := AIndent;
  LNextText         := '';
  LItemsIndent      := -1;
  LAlias            := '';
  LPrevRemainer     := '';
  LIsLiteral        := False;
  LCollectionItem   := 0;

  // Get last element in elements list, if it exists, and indent from it
  if AElements.Count > 0 then
    begin
      if AElements.Last.Key.IsEmpty() and (AElements.Last.Value.Equals('}') or AElements.Last.Value.Equals(']')) then
        LElementIndent  := AElements.Last.Indent
      else
        LElementIndent  := AElements.Last.Indent + 1;
      if (not AElements.Last.Value.IsEmpty()) and (LText.IsEmpty) then
        begin
          // Just get next row number for the message
          InternalYamlNextText( AYAML, LRow, LIndent, LRemainer, True, True );
          raise EYamlParsingException.CreateFmt( EYamlCollectionItemError, [LRow + 1] );
        end;
    end;

  // Put in the opener
  LElement.Indent     := LElementIndent;
  LElement.LineNumber := LRow + 1;
  LElement.Value      := '[';
  AElements.Add(LElement);
  LElement.Clear;

  while not LDone do
    begin

      LElement.Indent := LElementIndent;
      LText           := LRemainer;

      // Check what will be next, in case we need to jump somewhere
      LNextRow    := LRow;
      LNextIndent := LIndent;
      LNextText   := InternalYamlNextText( AYAML, LNextRow, LNextIndent, LRemainer, True, True );
      // To control collection items alignment
      if LItemsIndent = -1 then
        LItemsIndent := LNextIndent;

      // EOF
      if LNextRow < 0 then
        LDone := True
      // Outdent, exit
      else if LNextIndent < LItemsIndent then
        LDone := True
      // Next is not a collection item, exit
      else if (LNextIndent = LItemsIndent) and not (LNextText.StartsWith('- ') or LNextText.Equals('-')) then
        LDone := True
      // Go for it
      else
        begin

          // Backup references
          LPrevRemainer := LRemainer;

          // Read an item
          LType := InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, False );
          LCurrRow := LRow;

          // A trouple chain in item
          if (LType = TYamlTokenType.tokenKey) then
            begin
              if LText.Equals('<<') then
                raise EYamlParsingException.CreateFmt( EYamlMergeInCollectionError, [LRow + 1] );
              LIndent   := LIndent + LCollectionItem;
              LRemainer := LText + ': ' + LRemainer;
              InternalYamlProcessElements( AYAML, AElements, LRow, LIndent, LRemainer, AYesNoBool, AAllowDuplicateKeys );
              LIndent   := LIndent - LCollectionItem;
              LCurrRow := LRow;
            end
          // An inline array in item
          else if LText.StartsWith('[') then
            begin
              LRemainer := LText;
              InternalYamlProcessArray( AYAML, AElements, LRow, LIndent, LRemainer, AYesNoBool, AAllowDuplicateKeys );
              LCurrRow := LRow;
            end
          else
            begin
              if LText.IsEmpty then
                LElement.Value := 'null'
              else
                LElement.Value := LText;
              LElement.Literal  := LIsLiteral;
              LElement.Tag      := LTag;
              if not LAlias.IsEmpty then
                begin
                  if LAlias.StartsWith('*') then
                    LElement.Alias    := LAlias.Substring(1)
                  else
                    begin
                      LElement.Anchor   := LAlias.Substring(1);
                      // Avoid duplicated anchor names
                      if InternalYamlFindAnchor( AElements, LElement.Anchor ) >= 0 then
                        raise EYamlParsingException.CreateFmt( EYamlAnchorDuplicateError, [LRow + 1] );
                    end;
                end;

              LElement.LineNumber := LRow + 1;
              AElements.Add(LElement);
              LElement.Clear;
            end;
        end;

    end;

  // Put in the closer
  LElement.Indent     := LElementIndent;
  LElement.LineNumber := LCurrRow + 1;
  LElement.Value      := ']';
  AElements.Add(LElement);
  LElement.Clear;

  ARow  := LCurrRow;
  AText := LRemainer;
end;


// Process element pairs (key: value) from source
class procedure TYamlUtils.InternalYamlProcessElements( AYAML: TStrings; AElements: TYamlElements; var ARow, AIndent: Integer; var AText: string; AYesNoBool: boolean; AAllowDuplicateKeys: boolean );
var
  LType: TYamlTokenType;
  LElement: TYamlElement;
  LElementIndent: Integer;
  LRow: Integer;
  LCurrRow: Integer;
  LIndent: Integer;
  LText: string;
  LRemainer: string;
  LKeysList: TStringList;
  LDone: boolean;
  LNextRow: Integer;
  LNextIndent: Integer;
  LNextText: string;
  LAlias: string;
  LTag: string;
  LCollectionItem: Integer;
  LIsLiteral: boolean;
  LPrevRow: Integer;
  LPrevIndent: Integer;
  LPrevRemainer: string;
begin
  LElementIndent    := 0;
  LRow              := ARow;
  LCurrRow          := ARow;
  LIndent           := AIndent;
  LText             := AText;
  LRemainer         := AText;
  LKeysList         := nil;
  LDone             := False;
  LNextRow          := 0;
  LNextIndent       := AIndent;
  LNextText         := '';
  LAlias            := '';
  LCollectionItem   := 0;
  LIsLiteral        := False;
  LPrevRemainer     := '';

  // Get last element in elements list, if it exists, and indent from it
  if AElements.Count > 0 then
    begin
      if AElements.Last.Key.IsEmpty() and (AElements.Last.Value.Equals('}') or AElements.Last.Value.Equals(']')) then
        LElementIndent  := AElements.Last.Indent
      else
        LElementIndent  := AElements.Last.Indent + 1;
      if (not AElements.Last.Value.IsEmpty()) and (LText.IsEmpty) then
        begin
          // Just get next row number for the message
          InternalYamlNextText( AYAML, LRow, LIndent, LRemainer, True, True );
          raise EYamlParsingException.CreateFmt( EYamlInvalidIndentError, [LRow + 1] );
        end;
    end;

  // Put in the opener
  LElement.Indent     := LElementIndent;
  LElement.LineNumber := LRow + 1;
  LElement.Value      := '{';
  AElements.Add(LElement);
  LElement.Clear;

  // Control duplicated keys, if required
  if not AAllowDuplicateKeys then
    begin
      LKeysList := TStringList.Create;
      LKeysList.CaseSensitive := True;
    end;
  try

    while not LDone do
      begin

        LElement.Indent := LElementIndent;
        LText           := LRemainer;

        // Check what will be next, in case we need to jump somewhere
        LNextRow    := LRow;
        LNextIndent := LIndent;
        LNextText   := InternalYamlNextText( AYAML, LNextRow, LNextIndent, LRemainer, True, True );

        // EOF
        if LNextRow < 0 then
          LDone := True
        // Outdent / exit
        else if (LIndent <> -1) and (LNextIndent < LIndent) then
          LDone := True
        // A collection, process it
        else if LNextText.StartsWith('- ') or LNextText.Equals('-') then
          begin
            if LNextRow = LRow then
              raise EYamlParsingException.CreateFmt( EYamlCollectionItemError, [LRow + 1] );
            InternalYamlProcessCollection( AYAML, AElements, LRow, LNextIndent, LRemainer, AYesNoBool, AAllowDuplicateKeys );
            LCurrRow := LRow;
          end
        // An inline array, process it
        else if LNextText.StartsWith('[') then
          begin
            InternalYamlProcessArray( AYAML, AElements, LRow, LNextIndent, LRemainer, AYesNoBool, AAllowDuplicateKeys );
            LCurrRow := LRow;
          end
        // Indent, go in, recursive
        else if (LIndent <> -1) and (LNextIndent > LIndent) then
          begin
            InternalYamlProcessElements( AYAML, AElements, LRow, LNextIndent, LRemainer, AYesNoBool, AAllowDuplicateKeys );
            LCurrRow := LRow;
          end
        // Process this
        else
          begin
            // Get the key
            LType := InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, False );
            if LRow >= 0 then
              begin
                LCurrRow := LRow;
                if (LType <> TYamlTokenType.tokenKey) then
                  raise EYamlParsingException.CreateFmt( EYamlExpectedKeyError, [LRow + 1] );
                LElement.Key  := LText;
                LElement.Tag  := LTag;
                // Check for duplicated key?
                if (not AAllowDuplicateKeys) and (not LText.Equals('<<')) then
                  begin
                    if LKeysList.IndexOf(LText) >= 0 then
                      raise EYamlParsingException.CreateFmt( EYamlDuplicatedKeyError, [LRow + 1] );
                    LElement.LineNumber := LRow + 1;
                    LKeysList.Add(LText);
                  end;
                // Backup references
                LPrevRow      := LRow;
                LPrevIndent   := LIndent;
                LPrevRemainer := LRemainer;
                // Go for the value
                LText := LRemainer;
                LType := InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, False );
                if LRow >= 0 then
                  LCurrRow := LRow;
                // EOF
                if LRow < 0 then
                  begin
                    LElement.Value := 'null';
                    LDone := True;
                  end
                // An inline array is found
                else if LText.StartsWith('[') then
                  begin
                    // Restore references
                    LRow      := LPrevRow;
                    LIndent   := LPrevIndent;
                    LRemainer := LPrevRemainer;
                  end
                // A collection item is found
                else if (LCollectionItem > 0) or ((LText.StartsWith('- ') or LText.Equals('-')) and not LIsLiteral) then
                  begin
                    if LRow = LPrevRow then
                      raise EYamlParsingException.CreateFmt( EYamlCollectionItemError, [LRow + 1] );
                    // Restore references
                    LRow       := LPrevRow;
                    LIndent    := LPrevIndent;
                    LRemainer  := LPrevRemainer;
                  end
                // A new key, is it outdent/error ?
                else if (LType = TYamlTokenType.tokenKey) then
                  begin
                    if LRow = LPrevRow then
                      raise EYamlParsingException.CreateFmt( EYamlDoubleKeyError, [LRow + 1] );
                    if LIndent <= LPrevIndent then
                      LElement.Value := 'null';
                    if LIndent < LPrevIndent then
                      LDone := True;
                    // Restore references
                    LRow      := LPrevRow;
                    LIndent   := LPrevIndent;
                    LRemainer := LPrevRemainer;
                  end
                // A value
                else
                  begin
//                    if (LText.IsEmpty) and (LIndent <= LPrevIndent) then
//                      LElement.Value := 'null'
//                    else
                      LElement.Value    := LText;
                    LElement.Literal  := LIsLiteral;
                    LElement.Tag      := LTag;
                    if not LAlias.IsEmpty then
                      begin
                        if LAlias.StartsWith('*') then
                          LElement.Alias    := LAlias.Substring(1)
                        else
                          begin
                            LElement.Anchor   := LAlias.Substring(1);
                            // Avoid duplicated anchor names
                            if InternalYamlFindAnchor( AElements, LElement.Anchor ) >= 0 then
                              raise EYamlParsingException.CreateFmt( EYamlAnchorDuplicateError, [LRow + 1] );
                        end;
                      end;
                  end;
                if LElement.Key.Equals('<<') and (LElement.Alias.IsEmpty) then
                  raise EYamlParsingException.CreateFmt( EYamlMergeInvalidError, [LRow + 1] );
                LElement.LineNumber := LRow + 1;
                AElements.Add(LElement);
                LElement.Clear;
              end;
          end;
      end;

  finally
    if Assigned(LKeysList) then
      FreeAndNil(LKeysList)
  end;

  // Put in the closer
  LElement.Indent     := LElementIndent;
  LElement.LineNumber := LCurrRow + 1;
  LElement.Value      := '}';
  AElements.Add(LElement);
  LElement.Clear;

  ARow  := LCurrRow;
  AText := LRemainer;
end;


// Format a YAML value to JSON
class function  TYamlUtils.InternalYamlProcessJsonValue( AValue: string; ALiteral: boolean; ATag: string; ALineNumber: Integer; AYesNoBool: boolean  ): string;
var
  LValue: string;
  LInt64: Int64;
  LFloat: Extended;
  LDate: TDateTime;
  LFormatSettings: TFormatSettings;
  LValueType: string;
begin
  LFormatSettings.DecimalSeparator  := '.';
  LFormatSettings.ThousandSeparator := ',';
  LFormatSettings.DateSeparator     := '-';
  LFormatSettings.TimeSeparator     := ':';
  LFormatSettings.ShortDateFormat   := 'yyyy-mm-dd';
  LFormatSettings.ShortTimeFormat   := 'hh:nn:ss.z';
  LFormatSettings.LongTimeFormat    := 'hh:nn:ss.z';
  LValue := AValue;
  if (not LValue.IsEmpty) then
    begin
      // String tagged values are straight forward
      if (ATag = LTagStr) then
        begin
          LValueType := LTagStr;
          LValue := '"' + LValue + '"';
        end
      // Binary tagged values are also special
      else if (ATag = LTagBin) then
        begin
          LValueType := LTagBin;
          LValue := LValue;
        end
      else if (not ALiteral) and LValue.ToLower.Equals('null') then
        begin
          LValueType := LTagNull;
          LValue := 'null';
          if ATag = LTagMap then
            begin
              LValueType := LTagMap;
              LValue := '{}';
            end
          else if ATag = LTagSeq then
            begin
              LValueType := LTagSeq;
              LValue := '[]';
            end;
        end
      else if (not ALiteral) and LValue.ToLower.Equals('true') then
        begin
          LValueType := LTagBool;
          LValue := 'true';
        end
      else if (not ALiteral) and LValue.ToLower.Equals('false') then
        begin
          LValueType := LTagBool;
          LValue := 'false';
        end
      else if (not ALiteral) and (AYesNoBool) and LValue.ToLower.Equals('yes') then
        begin
          LValueType := LTagBool;
          LValue := 'true';
        end
      else if (not ALiteral) and (AYesNoBool) and LValue.ToLower.Equals('no') then
        begin
          LValueType := LTagBool;
          LValue := 'false';
        end
      else if (not ALiteral) and TryStrToInt64(LValue.Trim, LInt64) then
        begin
          LValueType := LTagInt;
          LValue := IntToStr(LInt64);
        end
      else if (not ALiteral) and TryStrToFloat(LValue.Trim, LFloat, LFormatSettings) then
        begin
          LValueType := LTagFloat;
          LValue := FloatToStr( LFloat, LFormatSettings );
        end
      else if (not ALiteral) and InternalTryStrToDateTime( LValue.Trim, LDate, LFormatSettings ) then
        begin
          LValueType := LTagTime;
          LValue := '"' + DateToISO8601(LDate, False ) + '"';
        end
      else
        begin
          LValueType := LTagStr;
          LValue := '"' + LValue + '"';
        end;
    end
  else
    begin
      if (ALiteral) or (ATag = '!!str') then
        begin
          LValueType := LTagStr;
          LValue := '"' + LValue + '"';
        end
      else if ATag = LTagMap then
        LValueType := LTagMap
      else if ATag = LTagSeq then
        LValueType := LTagSeq;
    end;
  // Check tag type (float will accept int as well)
  if (not ATag.IsEmpty) then
    if not ( (ATag = LTagFloat) and (LValueType.Equals(LTagInt) or LValueType.Equals(LTagFloat)) ) then
      if not LValueType.Equals(ATag) then
        raise EYamlParsingException.CreateFmt( EYamlInvalidValueForTagError, [ALineNumber] );

  Result := LValue;
end;


// Convert the prepared TYamlElements list to JSON
class procedure TYamlUtils.InternalYamlToJson( AElements: TYamlElements; AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: boolean );
var
  I, Z: Integer;
  LElement: TYamlElement;
  LNextElement: TYamlElement;
  LPrevElement: TYamlElement;
  LDisplacement: Integer;
  LIndent: Integer;
  LSpaces: string;
  LBinSpaces: string;
  LSeparator: string;
  LValue: string;
  LBase64Decoder: TNetEncoding;
  LBytes: TBytes;
  LSize: Integer;
begin
  LDisplacement := 0;
  AJSON.BeginUpdate;
  try
    AJSON.Clear;
    // Put it to json
    for I := 0 to AElements.Count - 1 do
      begin
        LSeparator  := '';
        LNextElement.Clear;
        LPrevElement.Clear;
        LElement      := AElements[I];
        if I > 0 then
          LPrevElement := AElements[I - 1];
        if I < AElements.Count - 1 then
          LNextElement := AElements[I + 1];
        if (LElement.Key.IsEmpty) and (LElement.Value.Equals('[') or LElement.Value.Equals('{')) then
          begin
            if (AJSON.Count = 0) then
              begin
                AJSON.Add( LElement.Value );
                Inc(LDisplacement);
              end
            else
              begin
                LIndent   := (LElement.Indent + LDisplacement - 1) * AIndentation;
                if LIndent < 0 then
                  LIndent := 0;
                LSpaces   := string.Create(' ', LIndent);
                if (LPrevElement.Value = '[') or (AJSON[ AJSON.Count - 1 ].EndsWith(',')) then
                  AJSON.Add( LSpaces + LElement.Value )
                else
                  AJSON[ AJSON.Count - 1 ] := AJSON[ AJSON.Count - 1 ] + ': ' + LElement.Value;
              end;
          end
        else if (LElement.Key.IsEmpty) and (LElement.Value.Equals(']') or LElement.Value.Equals('}')) then
          begin
            if (I = AElements.Count - 1) and (LDisplacement > 0) then
              LDisplacement := 0;
            LIndent   := (LElement.Indent + LDisplacement - 1) * AIndentation;
            if LIndent < 0 then
              LIndent := 0;
            LSpaces   := string.Create(' ', LIndent);
            if I < AElements.Count - 1 then
              begin
                if not (AElements[I+1].Value.Equals('}') or AElements[I+1].Value.Equals(']')) then
                  LSeparator := ',';
              end;
            AJSON.Add( LSpaces + LElement.Value + LSeparator );
          end
        else
          begin
            LIndent := (LElement.Indent + LDisplacement) * AIndentation;
            LSpaces := string.Create(' ', LIndent);
            LValue  := InternalYamlProcessJsonValue( LElement.Value, LElement.Literal, LElement.Tag, LElement.LineNumber, AYesNoBool );
            // Check tag !!map special case
            if (LElement.Tag = LTagMap) and (not LValue.Equals('{}')) then
              if not (LNextElement.Key.IsEmpty and LNextElement.Value.Equals('{')) then
                raise EYamlParsingException.CreateFmt( EYamlInvalidValueForTagError, [LElement.LineNumber] );
            // Check tag !!map special case
            if (LElement.Tag = LTagSeq) and (not LValue.Equals('[]')) then
              if not (LNextElement.Key.IsEmpty and LNextElement.Value.Equals('[')) then
                raise EYamlParsingException.CreateFmt( EYamlInvalidValueForTagError, [LElement.LineNumber] );
            // Other cases
            if (LNextElement.Indent >= LElement.Indent) and (not LValue.IsEmpty) and
              not (LNextElement.Value.Equals('}') or LNextElement.Value.Equals(']')) then
              LSeparator := ',';
            if LElement.Key.IsEmpty then
              AJSON.Add( LSpaces + LValue + LSeparator )
            else
              begin
                // Check tag !!binary special case
                if LElement.Tag = LTagBin then
                  begin
                    LBase64Decoder := System.NetEncoding.TNetEncoding.Base64String;
                    try
                      try
                        LBytes := LBase64Decoder.DecodeStringToBytes(LValue);
                      except
                        raise EYamlParsingException.CreateFmt( EYamlInvalidValueForTagError, [LElement.LineNumber] );
                      end;
                      LBinSpaces := string.Create(' ', LIndent + AIndentation);
                      LSize := Length(LBytes) - 1;
                      AJSON.Add( LSpaces + '"' + LElement.Key + '"' + ': ' +  '[' );
                      for Z := 0 to LSize do
                        begin
                          if Z < LSize then
                            AJSON.Add( LBinSpaces + IntToStr(LBytes[Z]) + ',' )
                          else
                            AJSON.Add( LBinSpaces + IntToStr(LBytes[Z]) )
                        end;
                      AJSON.Add( LSpaces + ']' + LSeparator );
                    finally
                      SetLength( LBytes, 0 );
                    end;
                  end
                else if LValue.IsEmpty then
                  AJSON.Add( LSpaces + '"' + LElement.Key +'"' + LSeparator )
                else
                  AJSON.Add( LSpaces + '"' + LElement.Key + '"' + ': ' +  LValue + LSeparator )
              end
          end;
      end;
  finally
    AJSON.EndUpdate;
  end;
end;


// Entry point to parse YAML to JSON
class procedure TYamlUtils.InternalYamlParse( AYAML, AJSON: TStrings; AIndentation: TJsonIdentation; AYesNoBool: boolean; AAllowDuplicateKeys: boolean );
var
  LElements: TYamlElements;
  LElement: TYamlElement;
  LType: TYamlTokenType;
  LRow: Integer;
  XRow: Integer;
  LIndent: Integer;
  LText: string;
  XText: string;
  LRemainer: string;
  LAlias: string;
  LTag: string;
  LCollectionItem: Integer;
  LIsLiteral: boolean;
begin
  LRow            := -1;
  LIndent         := -1;
  XRow            := -1;
  XText           := '';
  LRemainer       := '';
  LAlias          := '';
  LCollectionItem := 0;
  LIsLiteral      := False;

  // Read the first element to check what it is
  LType := InternalYamlReadToken( AYAML, XRow, LIndent, XText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, False );

  if (XRow >= 0) then
    begin

      // Reset variables
      LRow          := -1;
      LIndent       := -1;

      LElements := TYamlElements.Create;
      try

        // An inline array
        if XText.StartsWith('[') then
          InternalYamlProcessArray( AYAML, LElements, LRow, LIndent, LText, AYesNoBool, AAllowDuplicateKeys )
        // A collection
        else if (LCollectionItem > 0) or ((XText.StartsWith('- ') or XText.Equals('-')) and (not LIsLIteral)) then
          InternalYamlProcessCollection( AYAML, LElements, LRow, LIndent, LText, AYesNoBool, AAllowDuplicateKeys )
        // Single text yaml
        else if LType = TYamlTokenType.tokenValue then
          begin
            LElement.Value      := XText;
            LElement.Literal    := LIsLiteral;
            LElement.LineNumber := XRow + 1;
            LElement.Indent     := 0;
            LElement.Tag        := LTag;
            LElements.Add(LElement);
            LRow := XRow;
          end
        // Key: value pairs
        else
          begin
            if XText.StartsWith('|') or XText.StartsWith('>') then
              raise EYamlParsingException.CreateFmt( EYamlInvalidBlockError, [XRow + 1] );
            InternalYamlProcessElements( AYAML, LElements, LRow, LIndent, LText, AYesNoBool, AAllowDuplicateKeys );
          end;
        // Check if it's all consumed
        InternalYamlReadToken( AYAML, LRow, LIndent, LText, LRemainer, LAlias, LTag, LCollectionItem, LIsLiteral, False );
        if not LText.IsEmpty then
          raise EYamlParsingException.CreateFmt( EYamlUnconsumedContentError, [LRow + 1] );
        // Process aliases/anchors (fisrt)
        InternalYamlResolveAliases( LElements );
        // Process merges (having aliases/anchors already resolved)
        InternalYamlResolveMerges( LElements );
        // Convert all to JSON
        InternalYamlToJson( LElements, AJSON, AIndentation, AYesNoBool );
      finally
        FreeAndNil(LElements)
      end;
    end;

end;

// JSON to YAML section
// --------------------

// Process JSON object to YAML (a touple)
class procedure TYamlUtils.InternalJsonObjToYaml( AJSON: TJSONObject; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False; AYesNoBool: boolean = False );
var
  I, L: Integer;
  LElement: TJSONPair;
  LName: string;
  LValue: TJSONValue;
  LSpaces: string;
  LIndent: Integer;
  LLines: TArray<string>;
begin
  Inc(AIndent);
  try
    for I := 0 to AJSON.Count - 1 do
      begin
        LIndent := AIndent * AIndentation;
        if (AFromArray) and (I = 0) then
            LSpaces := string.Create( ' ', (AIndent - 1) * AIndentation ) + '- '
        else
          LSpaces := string.Create( ' ', LIndent );
        LElement  := AJSON.Pairs[I];
        LName     := LElement.JsonString.Value;
        LValue    := LElement.JsonValue;
        // Check for object type
        if (LValue is TJSONObject) then
          begin
            if (LValue as TJSONObject).Count = 0 then
              AOutStrings.Add( LSpaces + LName + ': {}' )
            else
              begin
                AOutStrings.Add( LSpaces + LName + ':' );
                InternalJsonObjToYaml( LValue as TJSONObject, AOutStrings, AIndentation, AIndent, False, AYesNoBool );
              end;
          end
        else if (LValue is TJSONArray) then
          begin
            if (LValue as TJSONArray).Count = 0 then
              AOutStrings.Add( LSpaces + LName + ': []' )
            else
              begin
                AOutStrings.Add( LSpaces + LName + ':' );
                InternalJsonArrToYaml( LValue as TJSONArray, AOutStrings, AIndentation, AIndent, False, AYesNoBool );
              end;
          end
        else
          begin
            LLines := InternalJsonValueToYaml(LValue, LIndent, AYesNoBool );
            try
              AOutStrings.Add( LSpaces + LName + ': ' + LLines[0] );
              for L := 1 to High(LLines) do
                AOutStrings.Add( LSpaces + LLines[L] );
            finally
              SetLength(LLines , 0);
              LLines := nil;
            end;
          end;
      end;
  finally
    Dec(AIndent);
  end;
end;


// Process JSON array to YAML
class procedure TYamlUtils.InternalJsonArrToYaml( AJSON: TJSONArray; AOutStrings: TStrings; AIndentation: TYamlIdentation; var AIndent: Integer; AFromArray: boolean = False; AYesNoBool: boolean = False );
var
  I, L: Integer;
  LValue: TJSONValue;
  LSpaces: string;
  LIndent: Integer;
  LLines: TArray<string>;
begin
  Inc(AIndent);
  try
    for I := 0 to AJSON.Count - 1 do
      begin
        LIndent := AIndent * AIndentation;
        if (AFromArray) and (I = 0) then
          LSpaces := string.Create( ' ', (AIndent - 1) * AIndentation ) + '- '
        else
          LSpaces := string.Create( ' ', LIndent );
        LValue  := AJSON.Items[I];
        // Check for object type
        if (LValue is TJSONObject) then
          begin
            if (LValue as TJSONObject).Count = 0 then
              AOutStrings.Add( LSpaces + '- {}' )
            else
              InternalJsonObjToYaml( LValue as TJSONObject, AOutStrings, AIndentation, AIndent, True, AYesNoBool );
          end
        // Check for array type
        else if (LValue is TJSONArray) then
          begin
            if (LValue as TJSONArray).Count = 0 then
              AOutStrings.Add( LSpaces + '- []' )
            else
              InternalJsonArrToYaml( LValue as TJSONArray, AOutStrings, AIndentation, AIndent, True, AYesNoBool );
          end
        else
          begin
            LLines := InternalJsonValueToYaml(LValue, LIndent, AYesNoBool );
            try
              AOutStrings.Add( LSpaces + '- ' + LLines[0] );
              for L := 1 to High(LLines) do
                AOutStrings.Add( LSpaces + LLines[L] );
            finally
              SetLength(LLines , 0);
              LLines := nil;
            end;
          end;
      end;
  finally
    Dec(AIndent);
  end;
end;


// Convert a value from JSON to YAML
class function  TYamlUtils.InternalJsonValueToYaml( AJSON: TJSONValue; AIndent: Integer = 0; AYesNoBool: boolean = False ): TArray<string>;
const
  LJsonLineFeed: string = chr(10);
var
  L: Integer;
  LText: string;
  LFloat: Extended;
  LFold: string;
  LChomp: string;
  LSpaces: string;
begin
  LFold   := '';
  LChomp  := '';
  LSpaces := '';
  // TJSONValue is already "unescaped"
  LText := AJSON.Value;
  if (AJSON is TJSONFalse) then
    begin
      if AYesNoBool then
        LText := 'no'
      else
        LText := 'false';
    end
  else if (AJSON is TJSONTrue) then
    begin
      if AYesNoBool then
        LText := 'yes'
      else
        LText := 'true';
    end
  else if (AJSON is TJSONNull) then
    begin
      LText := '';
    end
  else if (AJSON is TJSONNumber) then
    begin
      LFloat := TJSONNumber(AJSON).AsDouble;
      if Frac(LFloat) = 0 then
        LText := IntToStr( Trunc(LFloat) )
      else
        LText := FloatToStr(LFloat)
    end
  else if (AJSON is TJSONString) and not (AJSON is TJSONNumber) then
    begin
      if LText.Trim.IsEmpty then
        LText := ''''''
      else if LText.Contains(LJsonLineFeed) then  // Process multilines ...
        begin
          // Have we empty lines at the begining ?
          if LText.StartsWith(LJsonLineFeed) then
            LFold := '>';
          // Have linefeed at the middle ?
          if LText.Trim.Contains(LJsonLineFeed) then
            LFold := '|';
          // Have more that one empty line at the end ?
          if LText.EndsWith(LJsonLineFeed + LJsonLineFeed) then
            LChomp := '+'
          else if (not LFold.IsEmpty) and not (LText.EndsWith(LJsonLineFeed)) then
            LChomp := '-';
          // Recheck fold
          if not LChomp.IsEmpty and LFold.IsEmpty then
            LFold := '>';
          LText := LFold + LChomp + LJsonLineFeed + LText;
          Result := LText.Split( [LJsonLineFeed] );
          // Adjust identation
          if AIndent >= 0 then
            begin
              LSpaces := string.Create( ' ', AIndent + 1 );
              for L := 1 to High(Result) do
                Result[L] := LSpaces + Result[L];
            end;
        end;
    end;
  if Length(Result) = 0 then
    begin
      SetLength( Result, 1 );
      Result[0] := LText;
    end;
end;



// THE PUBLIC section
// ------------------

// JSON TO YAML
class function  TYamlUtils.JsonToYaml( AJSON: string; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False ): string;
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := nil;
  try
    LJSONValue := TJSONObject.ParseJSONValue( AJSON, False, True );
  except
    LJSONValue := TJSONString.Create( AJSON )
  end;
  try
    Result := JsonToYaml( LJSONValue, AIndentation, AYesNoBool );
  finally
    FreeAndNil(LJSONValue);
  end;
end;


class function  TYamlUtils.JsonToYaml( AJSON: TJSONValue; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False ): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    JsonToYaml( AJSON, LStrings, AIndentation, AYesNoBool );
    Result := LStrings.Text;
  finally
    LStrings.Free;
  end;
end;


class procedure TYamlUtils.JsonToYaml( AJSON: TStrings; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False );
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := nil;
  try
    LJSONValue := TJSONObject.ParseJSONValue( AJSON.Text, False, True );
  except
    if (AJSON.Count = 1) or ((AJSON.Count = 2) and (AJSON[1].Trim.IsEmpty)) then
      LJSONValue := TJSONString.Create( AJSON.Text )
    else
      raise;
  end;
  try
    JsonToYaml( LJSONValue, AOutStrings, AIndentation, AYesNoBool );
  finally
    FreeAndNil(LJSONValue);
  end;
end;


class procedure TYamlUtils.JsonToYaml( AJSON: TJSONValue; AOutStrings: TStrings; AIndentation: TYamlIdentation = 2; AYesNoBool: boolean = False );
var
  L: Integer;
  LIndent: Integer;
  LLines: TArray<string>;
begin
  LIndent := -1;
  AOutStrings.BeginUpdate;
  try
    AOutStrings.Clear;
    if (AJSON is TJSONObject) then
      InternalJsonObjToYaml( AJSON as TJSONObject, AOutStrings, AIndentation, LIndent, False, AYesNoBool )
    else if (AJSON is TJSONArray) then
      InternalJsonArrToYaml( AJSON as TJSONArray, AOutStrings, AIndentation, LIndent, False, AYesNoBool )
    else
      begin
        LLines := InternalJsonValueToYaml(AJSON, -1, AYesNoBool );
        try
          AOutStrings.Add( LLines[0] );
          for L := 1 to High(LLines) do
            AOutStrings.Add( LLines[L] );
        finally
          SetLength(LLines , 0);
          LLines := nil;
        end;
      end;
  finally
    AOutStrings.EndUpdate;
  end;
end;


// YAML TO JSON
class procedure TYamlUtils.YamlToJson( AYAML: TStrings; AOutStrings: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True );
begin
  InternalYamlParse( AYAML, AOutStrings, AIndentation, AYesNoBool, AAllowDuplicateKeys );
end;


class function  TYamlUtils.YamlToJson( AYAML: TStrings; AIndentation: TJsonIdentation = 2; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    YamlToJson( AYAML, LStrings, AIndentation, AYesNoBool, AAllowDuplicateKeys );
    Result := LStrings.Text;
  finally
    LStrings.Free;
  end;
end;


class function  TYamlUtils.YamlToJson( AYAML: string; AIndentation: TJsonIdentation = 2; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): string;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    LStrings.Text := AYAML;
    Result := YamlToJson( LStrings, AIndentation, AYesNoBool, AAllowDuplicateKeys );
  finally
    LStrings.Free;
  end;
end;


class function  TYamlUtils.YamlToJsonValue( AYAML: string; AIndentation: TJsonIdentation = 0; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): TJSONValue;
var
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  try
    LStrings.Text := AYAML;
    Result := YamlToJsonValue( LStrings, AIndentation, AYesNoBool, AAllowDuplicateKeys );
  finally
    LStrings.Free;
  end;
end;


class function  TYamlUtils.YamlToJsonValue( AYAML: TStrings; AIndentation: TJsonIdentation = 0; AYesNoBool: boolean = True; AAllowDuplicateKeys: boolean = True ): TJSONValue;
var
  LJSON: string;
begin
  LJSON := YamlToJson( AYAML, AIndentation, AYesNoBool, AAllowDuplicateKeys );
  Result := TJSONObject.ParseJSONValue( LJSON, False, True );
end;


class procedure TYamlUtils.JsonAsStrings( AJSON: TJSONValue; AOutStrings: TStrings; AIndentation: TJsonIdentation = 2 );
begin
  AOutStrings.Text := AJSON.Format(AIndentation);
end;


class function  TYamlUtils.JsonMinify( AJSON: string ): string;
var
  LLines: TStrings;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AJSON;
    Result := JSonMinify(LLines);
  finally
    FreeAndNil(LLines);
  end;
end;


class function  TYamlUtils.JsonMinify( AJSON: TStrings ): string;
var
  I: Integer;
begin
  for I := 0 to AJSON.Count - 1 do
    begin
      if Result.IsEmpty then
        Result := Result + AJSON[I].Trim
      else
        Result := Result + ' ' + AJSON[I].Trim
    end;
end;


class function  TYamlUtils.JsonMinify( AJSON: TJSONValue ): string;
var
  LLines: TStrings;
begin
  LLines := TStringList.Create;
  try
    JsonAsStrings( AJSON, LLines, 0 );
    Result := JSonMinify(LLines);
  finally
    FreeAndNil(LLines);
  end;
end;


end.
