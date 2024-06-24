unit uIced.Imports;

{
  Iced (Dis)Assembler

  TetzkatLipHoka 2022-2024
}

interface

{$DEFINE AUTO_INIT}               // AutoInit/DeInit DLL(s) during initialization/finalization
{.$DEFINE VERCHECK}                // Perform Version-Check and inform on missmatch
{$DEFINE OnlyWarnOnLowerVersions} 
{.$DEFINE SILENT}                 // Don't show any warnings (missing DLL, Version-Missmatch) but Linking Errors
{.$DEFINE CLOSE_APP_ON_FAIL}
{$DEFINE WARN_DLLs_IN_FOLDER}     // Warning if DLLs are present in Application-Folder
{.$DEFINE IGNORE_LINKING_ERRORS}  // Ignore linking errors (DEBUG)
{.$DEFINE LIST_MISSING_MODULES}   // uses MemoryModule

// ResourceFile
{$DEFINE ResourceMode}            // Load DLL from Resourcefile
{$IFDEF ResourceMode}
  {.$R Iced.res}                   // DLL-ResourceFile (each DLLName without extension as RCDATA)
  {$IFDEF Win64}
  {$R Iced64.res}                  // DLL-ResourceFile (each DLLName without extension as RCDATA)
  {$ELSE}
  {$R Iced86.res}                  // DLL-ResourceFile (each DLLName without extension as RCDATA)
  {$ENDIF}
{$ENDIF}

{$DEFINE ResourceCompression}     // DLLs in ResourceFile are 7zip compressed (JEDI-Unit)
{$DEFINE PREFER_DLL_IN_FOLDER}    // If DLL is present in ApplicationFolder use it
{$DEFINE MemoryModule}            // use MemoryModule (Load without HDD-caching)

{$DEFINE GetModuleHandle}         // Try GetModuleHandle before LoadLibrary
{.$DEFINE ONLY_LOADLIBRARY_ERRORS} // Ignore 'GetLastError <> ERROR_SUCCESS' unless LoadLibrary actually failed

{$IF CompilerVersion >= 22}
  {$LEGACYIFEND ON}
{$IFEND}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$DEFINE section_INTERFACE_USES}
{$I DynamicDLL.inc}
{$UNDEF section_INTERFACE_USES}
,uIced.Types
;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$DEFINE section_INTERFACE}
{$I DynamicDLL.inc}
{$UNDEF section_INTERFACE}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Constantes~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  DLLCount_   = 1;
var
  DLLPath_    : Array [0..DLLCount_-1] of String = ( '' );

const
  DLLLoadDLL_ : Array [0..DLLCount_-1] of boolean = ( True );
  {$IFDEF Win64}
  DLLName_    : Array [0..DLLCount_-1] of String = ( 'Iced64.dll' );
  {$ELSE}
  DLLName_    : Array [0..DLLCount_-1] of String = ( 'Iced.dll' );
  {$ENDIF}
  DLLVersion_ : Array [0..DLLCount_-1] of String = ( '1.0.4.0' );
  {$IFDEF ResourceMode}
  DLLPass_    : Array [0..DLLCount_-1] of String = ( '' );
  {$ENDIF}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~DLL Declarations~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$WARNINGS OFF}

{$DEFINE section_Declaration} // Include
{.$I Iced.inc}
{$UNDEF section_Declaration}

var
  // Free Memory
  IcedFreeMemory : function( Pointer : Pointer ) : Boolean; cdecl = nil;

  // Creates a decoder
  //
  // # Errors
  // Fails if `bitness` is not one of 16, 32, 64.
  //
  // # Arguments
  // * `bitness`: 16, 32 or 64
  // * `data`: Data to decode
  // * `data`: ByteSize of `Data`
  // * `options`: Decoder options, `0` or eg. `DecoderOptions::NO_INVALID_CHECK | DecoderOptions::AMD`
  Decoder_Create : function( Bitness : Cardinal; Data : PByte; DataSize : NativeUInt; IP : UInt64; Options : Cardinal = doNONE ) : Pointer; cdecl = nil;

  // Returns `true` if there's at least one more byte to decode. It doesn't verify that the
  // next instruction is valid, it only checks if there's at least one more byte to read.
  // See also [`position()`] and [`max_position()`]
  //
  // It's not required to call this method. If this method returns `false`, then [`decode_out()`]
  // and [`decode()`] will return an instruction whose [`code()`] == [`Code::INVALID`].
  Decoder_CanDecode : function( Decoder : Pointer ) : Boolean; cdecl = nil;

  // Gets the current `IP`/`EIP`/`RIP` value, see also [`position()`]
  Decoder_GetIP : function( Decoder : Pointer ) : UInt64; cdecl = nil;

  // Sets the current `IP`/`EIP`/`RIP` value, see also [`try_set_position()`]
  // This method only updates the IP value, it does not change the data position, use [`try_set_position()`] to change the position.
  Decoder_SetIP : function ( Decoder : Pointer; Value : UInt64 ) : boolean; cdecl = nil;

  // Gets the bitness (16, 32 or 64)
  Decoder_GetBitness : function( Decoder : Pointer ) : Cardinal; cdecl = nil;

  // Gets the max value that can be passed to [`try_set_position()`]. This is the size of the data that gets
  // decoded to instructions and it's the length of the slice that was passed to the constructor.
  Decoder_GetMaxPosition : function( Decoder : Pointer ) : NativeUInt; cdecl = nil;

  // Gets the current data position. This value is always <= [`max_position()`].
  // When [`position()`] == [`max_position()`], it's not possible to decode more
  // instructions and [`can_decode()`] returns `false`.
  Decoder_GetPosition : function( Decoder : Pointer ) : NativeUInt; cdecl = nil;

  // Sets the current data position, which is the index into the data passed to the constructor.
  // This value is always <= [`max_position()`]
  Decoder_SetPosition : function ( Decoder : Pointer; Value : NativeUInt ) : boolean; cdecl = nil;

  // Gets the last decoder error. Unless you need to know the reason it failed,
  // it's better to check [`instruction.is_invalid()`].
  Decoder_GetLastError : function( Decoder : Pointer ) : TDecoderError; cdecl = nil;

  // Decodes and returns the next instruction, see also [`decode_out(&mut Instruction)`]
  // which avoids copying the decoded instruction to the caller's return variable.
  // See also [`last_error()`].
  Decoder_Decode : procedure( Decoder : Pointer; var Instruction : TInstruction ); cdecl = nil;

  // Gets the offsets of the constants (memory displacement and immediate) in the decoded instruction.
  // The caller can check if there are any relocations at those addresses.
  //
  // # Arguments
  // * `instruction`: The latest instruction that was decoded by this decoder
  Decoder_GetConstantOffsets : function( Decoder : Pointer; var Instruction : TInstruction; var ConstantOffsets : TConstantOffsets ) : Boolean; cdecl = nil;

  // Creates a formatter Output Callback
  FormatterOutput_Create : function( Callback : TFormatterOutputCallback; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Creates a masm formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  MasmFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Format Instruction
  MasmFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ); cdecl = nil;
  MasmFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl = nil;

  // Creates a Nasm formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  NasmFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Format Instruction
  NasmFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ); cdecl = nil;
  NasmFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl = nil;

  // Creates a Gas formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  GasFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Format Instruction
  GasFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl = nil;
  GasFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl = nil;

  // Creates a Intel formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  IntelFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Format Instruction
  IntelFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl = nil;
  IntelFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl = nil;

  // Creates a Fast formatter (Specialized)
  // NOTE: Fast Formatter only supports Specialized-Options
  FastFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Format Instruction
  FastFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl = nil;

  // Creates a Specialized formatter
  SpecializedFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; DBDWDDDQ : Boolean = False; UserData : Pointer = nil ) : Pointer; cdecl = nil;

  // Format Instruction
  SpecializedFormatter_Format : procedure( Formatter : Pointer; FormatterType : TIcedSpecializedFormatterType; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl = nil;

// Options
  // NOTE: Specialized Formatter only supports the following Options

  // Always show the size of memory operands
  //
  // Default | Value | Example | Example
  // --------|-------|---------|--------
  // _ | `true` | `mov eax,dword ptr [ebx]` | `add byte ptr [eax],0x12`
  // X | `false` | `mov eax,[ebx]` | `add byte ptr [eax],0x12`
  SpecializedFormatter_GetAlwaysShowMemorySize : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType ) : boolean; cdecl = nil;

  // Always show the size of memory operands
  //
  // Default | Value | Example | Example
  // --------|-------|---------|--------
  // _ | `true` | `mov eax,dword ptr [ebx]` | `add byte ptr [eax],0x12`
  // X | `false` | `mov eax,[ebx]` | `add byte ptr [eax],0x12`
  //
  // # Arguments
  // * `value`: New value
  SpecializedFormatter_SetAlwaysShowMemorySize : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType; Value : Boolean ) : boolean; cdecl = nil;

  // Use a hex prefix ( `0x` ) or a hex suffix ( `h` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x5A`
  // X | `false` | `5Ah`
  SpecializedFormatter_GetUseHexPrefix : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType ) : boolean; cdecl = nil;

  // Use a hex prefix ( `0x` ) or a hex suffix ( `h` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x5A`
  // X | `false` | `5Ah`
  //
  // # Arguments
  // * `value`: New value
  SpecializedFormatter_SetUseHexPrefix : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType; Value : Boolean ) : boolean; cdecl = nil;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Formatter Options
  // Format Instruction
  Formatter_Format : procedure( Formatter : Pointer; FormatterType : TIcedFormatterType; var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ); cdecl = nil;
  Formatter_FormatCallback : procedure( Formatter : Pointer; FormatterType : TIcedFormatterType; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl = nil;

  // Prefixes are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `REP stosd`
  // X | `false` | `rep stosd`
  Formatter_GetUpperCasePrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Prefixes are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `REP stosd`
  // X | `false` | `rep stosd`
  //
  // # Arguments
  //
  // * `value`: New value
  Formatter_SetUpperCasePrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Mnemonics are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV rcx,rax`
  // X | `false` | `mov rcx,rax`
  Formatter_GetUpperCaseMnemonics : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Mnemonics are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV rcx,rax`
  // X | `false` | `mov rcx,rax`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseMnemonics : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Registers are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov RCX,[RAX+RDX*8]`
  // X | `false` | `mov rcx,[rax+rdx*8]`
  Formatter_GetUpperCaseRegisters : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Registers are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov RCX,[RAX+RDX*8]`
  // X | `false` | `mov rcx,[rax+rdx*8]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseRegisters : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Keywords are uppercased ( eg. `BYTE PTR`, `SHORT` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov BYTE PTR [rcx],12h`
  // X | `false` | `mov byte ptr [rcx],12h`
  Formatter_GetUpperCaseKeyWords : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Keywords are uppercased ( eg. `BYTE PTR`, `SHORT` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov BYTE PTR [rcx],12h`
  // X | `false` | `mov byte ptr [rcx],12h`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseKeyWords : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Uppercase decorators, eg. `{z  ); `, `{sae  ); `, `{rd-sae  ); ` ( but not opmask registers: `{k1  ); ` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `vunpcklps xmm2{k5  ); {Z  ); ,xmm6,dword bcst [rax+4]`
  // X | `false` | `vunpcklps xmm2{k5  ); {z  ); ,xmm6,dword bcst [rax+4]`
  Formatter_GetUpperCaseDecorators : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Uppercase decorators, eg. `{z  ); `, `{sae  ); `, `{rd-sae  ); ` ( but not opmask registers: `{k1  ); ` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `vunpcklps xmm2{k5  ); {Z  ); ,xmm6,dword bcst [rax+4]`
  // X | `false` | `vunpcklps xmm2{k5  ); {z  ); ,xmm6,dword bcst [rax+4]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseDecorators : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Everything is uppercased, except numbers and their prefixes/suffixes
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV EAX,GS:[RCX*4+0ffh]`
  // X | `false` | `mov eax,gs:[rcx*4+0ffh]`
  Formatter_GetUpperCaseEverything : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Everything is uppercased, except numbers and their prefixes/suffixes
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV EAX,GS:[RCX*4+0ffh]`
  // X | `false` | `mov eax,gs:[rcx*4+0ffh]`
  //
  // # Arguments
  //
  // * `value`: New value
  Formatter_SetUpperCaseEverything : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Character index ( 0-based ) where the first operand is formatted. Can be set to 0 to format it immediately after the mnemonic.
  // At least one space or tab is always added between the mnemonic and the first operand.
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `0` | `mov�rcx,rbp`
  // _ | `8` | `mov�����rcx,rbp`
  Formatter_GetFirstOperandCharIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl = nil;

  // Character index ( 0-based ) where the first operand is formatted. Can be set to 0 to format it immediately after the mnemonic.
  // At least one space or tab is always added between the mnemonic and the first operand.
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `0` | `mov�rcx,rbp`
  // _ | `8` | `mov�����rcx,rbp`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetFirstOperandCharIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl = nil;

  // Size of a tab character or 0 to use spaces
  //
  // - Default: `0`
  Formatter_GetTabSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl = nil;

  // Size of a tab character or 0 to use spaces
  //
  // - Default: `0`
  //
  // # Arguments
  //
  // * `value`: New value
  Formatter_SetTabSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl = nil;

  // Add a space after the operand separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov rax, rcx`
  // X | `false` | `mov rax,rcx`
  Formatter_GetSpaceAfterOperandSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add a space after the operand separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov rax, rcx`
  // X | `false` | `mov rax,rcx`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceAfterOperandSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Add a space between the memory expression and the brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[ rcx+rdx ]`
  // X | `false` | `mov eax,[rcx+rdx]`
  Formatter_GetSpaceAfterMemoryBracket : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add a space between the memory expression and the brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[ rcx+rdx ]`
  // X | `false` | `mov eax,[rcx+rdx]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceAfterMemoryBracket : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Add spaces between memory operand `+` and `-` operators
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx + rdx*8 - 80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  Formatter_GetSpaceBetweenMemoryAddOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add spaces between memory operand `+` and `-` operators
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx + rdx*8 - 80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceBetweenMemoryAddOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Add spaces between memory operand `*` operator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx+rdx * 8-80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  Formatter_GetSpaceBetweenMemoryMulOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add spaces between memory operand `*` operator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx+rdx * 8-80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceBetweenMemoryMulOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Show memory operand scale value before the index register
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[8*rdx]`
  // X | `false` | `mov eax,[rdx*8]`
  Formatter_GetScaleBeforeIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show memory operand scale value before the index register
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[8*rdx]`
  // X | `false` | `mov eax,[rdx*8]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetScaleBeforeIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Always show the scale value even if it's `*1`
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rbx+rcx*1]`
  // X | `false` | `mov eax,[rbx+rcx]`
  Formatter_GetAlwaysShowScale : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Always show the scale value even if it's `*1`
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rbx+rcx*1]`
  // X | `false` | `mov eax,[rbx+rcx]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetAlwaysShowScale : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Always show the effective segment register. If the option is `false`, only show the segment register if
  // there's a segment override prefix.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ds:[ecx]`
  // X | `false` | `mov eax,[ecx]`
  Formatter_GetAlwaysShowSegmentRegister : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Always show the effective segment register. If the option is `false`, only show the segment register if
  // there's a segment override prefix.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ds:[ecx]`
  // X | `false` | `mov eax,[ecx]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetAlwaysShowSegmentRegister : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Show zero displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx*2+0]`
  // X | `false` | `mov eax,[rcx*2]`
  Formatter_GetShowZeroDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show zero displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx*2+0]`
  // X | `false` | `mov eax,[rcx*2]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetShowZeroDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Hex number prefix or an empty string, eg. `"0x"`
  //
  // - Default: `""` ( masm/nasm/intel ), `"0x"` ( gas )
  Formatter_GetHexPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Hex number prefix or an empty string, eg. `"0x"`
  //
  // - Default: `""` ( masm/nasm/intel ), `"0x"` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetHexPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Hex number suffix or an empty string, eg. `"h"`
  //
  // - Default: `"h"` ( masm/nasm/intel ), `""` ( gas )
  Formatter_GetHexSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Hex number suffix or an empty string, eg. `"h"`
  //
  // - Default: `"h"` ( masm/nasm/intel ), `""` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetHexSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `0x12345678`
  // X | `4` | `0x1234_5678`
  Formatter_GetHexDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `0x12345678`
  // X | `4` | `0x1234_5678`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetHexDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl = nil;

  // Decimal number prefix or an empty string
  //
  // - Default: `""`
  Formatter_GetDecimalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Decimal number prefix or an empty string
  //
  // - Default: `""`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDecimalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Decimal number suffix or an empty string
  //
  // - Default: `""`
  Formatter_GetDecimalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Decimal number suffix or an empty string
  //
  // - Default: `""`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDecimalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `12345678`
  // X | `3` | `12_345_678`
  Formatter_GetDecimalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `12345678`
  // X | `3` | `12_345_678`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDecimalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl = nil;

  // Octal number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0"` ( gas )
  Formatter_GetOctalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Octal number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0"` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetOctalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Octal number suffix or an empty string
  //
  // - Default: `"o"` ( masm/nasm/intel ), `""` ( gas )
  Formatter_GetOctalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Octal number suffix or an empty string
  //
  // - Default: `"o"` ( masm/nasm/intel ), `""` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetOctalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `12345670`
  // X | `4` | `1234_5670`
  Formatter_GetOctalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `12345670`
  // X | `4` | `1234_5670`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetOctalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl = nil;

  // Binary number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0b"` ( gas )
  Formatter_GetBinaryPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Binary number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0b"` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBinaryPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Binary number suffix or an empty string
  //
  // - Default: `"b"` ( masm/nasm/intel ), `""` ( gas )
  Formatter_GetBinarySuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Binary number suffix or an empty string
  //
  // - Default: `"b"` ( masm/nasm/intel ), `""` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBinarySuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `11010111`
  // X | `4` | `1101_0111`
  Formatter_GetBinaryDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl = nil;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `11010111`
  // X | `4` | `1101_0111`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBinaryDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl = nil;

  // Digit separator or an empty string. See also eg. [`hex_digit_group_size(  )`]
  //
  // [`hex_digit_group_size(  )`]: #method.hex_digit_group_size
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `""` | `0x12345678`
  // _ | `"_"` | `0x1234_5678`
  Formatter_GetDigitSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl = nil;

  // Digit separator or an empty string. See also eg. [`hex_digit_group_size(  )`]
  //
  // [`hex_digit_group_size(  )`]: #method.hex_digit_group_size
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `""` | `0x12345678`
  // _ | `"_"` | `0x1234_5678`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDigitSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl = nil;

  // Add leading zeros to hexadecimal/octal/binary numbers.
  // This option has no effect on branch targets and displacements, use [`branch_leading_zeros`]
  // and [`displacement_leading_zeros`].
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x0000000A`/`0000000Ah`
  // X | `false` | `0xA`/`0Ah`
  Formatter_GetLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add leading zeros to hexadecimal/octal/binary numbers.
  // This option has no effect on branch targets and displacements, use [`branch_leading_zeros`]
  // and [`displacement_leading_zeros`].
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x0000000A`/`0000000Ah`
  // X | `false` | `0xA`/`0Ah`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Use uppercase hex digits
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0xFF`
  // _ | `false` | `0xff`
  Formatter_GetUppercaseHex : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Use uppercase hex digits
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0xFF`
  // _ | `false` | `0xff`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUppercaseHex : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Small hex numbers ( -9 .. 9 ) are shown in decimal
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `9`
  // _ | `false` | `0x9`
  Formatter_GetSmallHexNumbersInDecimal : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Small hex numbers ( -9 .. 9 ) are shown in decimal
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `9`
  // _ | `false` | `0x9`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSmallHexNumbersInDecimal : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Add a leading zero to hex numbers if there's no prefix and the number starts with hex digits `A-F`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0FFh`
  // _ | `false` | `FFh`
  Formatter_GetAddLeadingZeroToHexNumbers : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add a leading zero to hex numbers if there's no prefix and the number starts with hex digits `A-F`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0FFh`
  // _ | `false` | `FFh`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetAddLeadingZeroToHexNumbers : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Number base
  //
  // - Default: [`Hexadecimal`]
  //
  // [`Hexadecimal`]: enum.NumberBase.html#variant.Hexadecimal
  Formatter_GetNumberBase : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TNumberBase; cdecl = nil;

  // Number base
  //
  // - Default: [`Hexadecimal`]
  //
  // [`Hexadecimal`]: enum.NumberBase.html#variant.Hexadecimal
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetNumberBase : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TNumberBase ) : boolean; cdecl = nil;

  // Add leading zeros to branch offsets. Used by `CALL NEAR`, `CALL FAR`, `JMP NEAR`, `JMP FAR`, `Jcc`, `LOOP`, `LOOPcc`, `XBEGIN`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je 00000123h`
  // _ | `false` | `je 123h`
  Formatter_GetBranchLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add leading zeros to branch offsets. Used by `CALL NEAR`, `CALL FAR`, `JMP NEAR`, `JMP FAR`, `Jcc`, `LOOP`, `LOOPcc`, `XBEGIN`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je 00000123h`
  // _ | `false` | `je 123h`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBranchLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Show immediate operands as signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,-1`
  // X | `false` | `mov eax,FFFFFFFF`
  Formatter_GetSignedImmediateOperands : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show immediate operands as signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,-1`
  // X | `false` | `mov eax,FFFFFFFF`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSignedImmediateOperands : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Displacements are signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov al,[eax-2000h]`
  // _ | `false` | `mov al,[eax+0FFFFE000h]`
  Formatter_GetSignedMemoryDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Displacements are signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov al,[eax-2000h]`
  // _ | `false` | `mov al,[eax+0FFFFE000h]`
  //
  // # Arguments
  //
  // * `value`: New value
  Formatter_SetSignedMemoryDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Add leading zeros to displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov al,[eax+00000012h]`
  // X | `false` | `mov al,[eax+12h]`
  Formatter_GetDisplacementLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Add leading zeros to displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov al,[eax+00000012h]`
  // X | `false` | `mov al,[eax+12h]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDisplacementLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Options that control if the memory size ( eg. `DWORD PTR` ) is shown or not.
  // This is ignored by the gas ( AT&T ) formatter.
  //
  // - Default: [`Default`]
  //
  // [`Default`]: enum.MemorySizeOptions.html#variant.Default
  Formatter_GetMemorySizeOptions : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TMemorySizeOptions; cdecl = nil;

  // Options that control if the memory size ( eg. `DWORD PTR` ) is shown or not.
  // This is ignored by the gas ( AT&T ) formatter.
  //
  // - Default: [`Default`]
  //
  // [`Default`]: enum.MemorySizeOptions.html#variant.Default
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetMemorySizeOptions : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TMemorySizeOptions ) : boolean; cdecl = nil;

  // Show `RIP+displ` or the virtual address
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rip+12345678h]`
  // X | `false` | `mov eax,[1029384756AFBECDh]`
  Formatter_GetRipRelativeAddresses : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show `RIP+displ` or the virtual address
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rip+12345678h]`
  // X | `false` | `mov eax,[1029384756AFBECDh]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetRipRelativeAddresses : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Show `NEAR`, `SHORT`, etc if it's a branch instruction
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je short 1234h`
  // _ | `false` | `je 1234h`
  Formatter_GetShowBranchSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show `NEAR`, `SHORT`, etc if it's a branch instruction
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je short 1234h`
  // _ | `false` | `je 1234h`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetShowBranchSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Use pseudo instructions
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `vcmpnltsd xmm2,xmm6,xmm3`
  // _ | `false` | `vcmpsd xmm2,xmm6,xmm3,5`
  Formatter_GetUsePseudoOps : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Use pseudo instructions
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `vcmpnltsd xmm2,xmm6,xmm3`
  // _ | `false` | `vcmpsd xmm2,xmm6,xmm3,5`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUsePseudoOps : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Show the original value after the symbol name
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[myfield ( 12345678 )]`
  // X | `false` | `mov eax,[myfield]`
  Formatter_GetShowSymbolAddress : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show the original value after the symbol name
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[myfield ( 12345678 )]`
  // X | `false` | `mov eax,[myfield]`
  //
  // # Arguments
  //
  // * `value`: New value
  Formatter_SetShowSymbolAddress : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // ( gas only ) : If `true`, the formatter doesn't add `%` to registers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ecx`
  // X | `false` | `mov %eax,%ecx`
  GasFormatter_GetNakedRegisters : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( gas only ) : If `true`, the formatter doesn't add `%` to registers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ecx`
  // X | `false` | `mov %eax,%ecx`
  //
  // # Arguments
  // * `value`: New value
  GasFormatter_SetNakedRegisters : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // ( gas only ) : Shows the mnemonic size suffix even when not needed
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `movl %eax,%ecx`
  // X | `false` | `mov %eax,%ecx`
  GasFormatter_GetShowMnemonicSizeSuffix : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( gas only ) : Shows the mnemonic size suffix even when not needed
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `movl %eax,%ecx`
  // X | `false` | `mov %eax,%ecx`
  //
  // # Arguments
  // * `value`: New value
  GasFormatter_SetShowMnemonicSizeSuffix : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // ( gas only ) : Add a space after the comma if it's a memory operand
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `( %eax, %ecx, 2 )`
  // X | `false` | `( %eax,%ecx,2 )`
  GasFormatter_GetSpaceAfterMemoryOperandComma : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( gas only ) : Add a space after the comma if it's a memory operand
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `( %eax, %ecx, 2 )`
  // X | `false` | `( %eax,%ecx,2 )`
  //
  // # Arguments
  // * `value`: New value
  GasFormatter_SetSpaceAfterMemoryOperandComma : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // ( masm only ) : Add a `DS` segment override even if it's not present. Used if it's 16/32-bit code and mem op is a displ
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov eax,ds:[12345678]`
  // _ | `false` | `mov eax,[12345678]`
  MasmFormatter_GetAddDsPrefix32 : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( masm only ) : Add a `DS` segment override even if it's not present. Used if it's 16/32-bit code and mem op is a displ
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov eax,ds:[12345678]`
  // _ | `false` | `mov eax,[12345678]`
  //
  // # Arguments
  // * `value`: New value
  MasmFormatter_SetAddDsPrefix32 : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // ( masm only ) : Show symbols in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+symbol]` / `[symbol]`
  // _ | `false` | `symbol[ecx]` / `symbol`
  MasmFormatter_GetSymbolDisplacementInBrackets : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( masm only ) : Show symbols in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+symbol]` / `[symbol]`
  // _ | `false` | `symbol[ecx]` / `symbol`
  //
  // # Arguments
  // * `value`: New value
  MasmFormatter_SetSymbolDisplacementInBrackets : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // ( masm only ) : Show displacements in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+1234h]`
  // _ | `false` | `1234h[ecx]`
  MasmFormatter_GetDisplacementInBrackets : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( masm only ) : Show displacements in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+1234h]`
  // _ | `false` | `1234h[ecx]`
  //
  // # Arguments
  // * `value`: New value
  MasmFormatter_SetDisplacementInBrackets : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // ( nasm only ) : Shows `BYTE`, `WORD`, `DWORD` or `QWORD` if it's a sign extended immediate operand value
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `or rcx,byte -1`
  // X | `false` | `or rcx,-1`
  NasmFormatter_GetShowSignExtendedImmediateSize : function( Formatter: Pointer ) : boolean; cdecl = nil;

  // ( nasm only ) : Shows `BYTE`, `WORD`, `DWORD` or `QWORD` if it's a sign extended immediate operand value
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `or rcx,byte -1`
  // X | `false` | `or rcx,-1`
  //
  // # Arguments
  // * `value`: New value
  NasmFormatter_SetShowSignExtendedImmediateSize : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl = nil;

  // Use `st( 0 )` instead of `st` if `st` can be used. Ignored by the nasm formatter.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `fadd st( 0 ),st( 3 )`
  // X | `false` | `fadd st,st( 3 )`
  Formatter_GetPreferST0 : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Use `st( 0 )` instead of `st` if `st` can be used. Ignored by the nasm formatter.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `fadd st( 0 ),st( 3 )`
  // X | `false` | `fadd st,st( 3 )`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetPreferST0 : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Show useless prefixes. If it has useless prefixes, it could be data and not code.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `es rep add eax,ecx`
  // X | `false` | `add eax,ecx`
  Formatter_GetShowUselessPrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl = nil;

  // Show useless prefixes. If it has useless prefixes, it could be data and not code.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `es rep add eax,ecx`
  // X | `false` | `add eax,ecx`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetShowUselessPrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JB` / `JC` / `JNAE` )
  //
  // Default: `JB`, `CMOVB`, `SETB`
  Formatter_GetCC_b : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_b; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JB` / `JC` / `JNAE` )
  //
  // Default: `JB`, `CMOVB`, `SETB`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_b : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_b ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JAE` / `JNB` / `JNC` )
  //
  // Default: `JAE`, `CMOVAE`, `SETAE`
  Formatter_GetCC_ae : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_ae; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JAE` / `JNB` / `JNC` )
  //
  // Default: `JAE`, `CMOVAE`, `SETAE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_ae : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_ae ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JE` / `JZ` )
  //
  // Default: `JE`, `CMOVE`, `SETE`, `LOOPE`, `REPE`
  Formatter_GetCC_e : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_e; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JE` / `JZ` )
  //
  // Default: `JE`, `CMOVE`, `SETE`, `LOOPE`, `REPE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_e : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_e ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JNE` / `JNZ` )
  //
  // Default: `JNE`, `CMOVNE`, `SETNE`, `LOOPNE`, `REPNE`
  Formatter_GetCC_ne : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_ne; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JNE` / `JNZ` )
  //
  // Default: `JNE`, `CMOVNE`, `SETNE`, `LOOPNE`, `REPNE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_ne : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_ne ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JBE` / `JNA` )
  //
  // Default: `JBE`, `CMOVBE`, `SETBE`
  Formatter_GetCC_be : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_be; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JBE` / `JNA` )
  //
  // Default: `JBE`, `CMOVBE`, `SETBE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_be : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_be ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JA` / `JNBE` )
  //
  // Default: `JA`, `CMOVA`, `SETA`
  Formatter_GetCC_a : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_a; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JA` / `JNBE` )
  //
  // Default: `JA`, `CMOVA`, `SETA`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_a : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_a ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JP` / `JPE` )
  //
  // Default: `JP`, `CMOVP`, `SETP`
  Formatter_GetCC_p : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_p; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JP` / `JPE` )
  //
  // Default: `JP`, `CMOVP`, `SETP`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_p : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_p ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JNP` / `JPO` )
  //
  // Default: `JNP`, `CMOVNP`, `SETNP`
  Formatter_GetCC_np : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_np; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JNP` / `JPO` )
  //
  // Default: `JNP`, `CMOVNP`, `SETNP`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_np : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_np ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JL` / `JNGE` )
  //
  // Default: `JL`, `CMOVL`, `SETL`
  Formatter_GetCC_l : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_l; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JL` / `JNGE` )
  //
  // Default: `JL`, `CMOVL`, `SETL`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_l : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_l ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JGE` / `JNL` )
  //
  // Default: `JGE`, `CMOVGE`, `SETGE`
  Formatter_GetCC_ge : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_ge; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JGE` / `JNL` )
  //
  // Default: `JGE`, `CMOVGE`, `SETGE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_ge : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_ge ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JLE` / `JNG` )
  //
  // Default: `JLE`, `CMOVLE`, `SETLE`
  Formatter_GetCC_le : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_le; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JLE` / `JNG` )
  //
  // Default: `JLE`, `CMOVLE`, `SETLE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_le : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_le ) : boolean; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JG` / `JNLE` )
  //
  // Default: `JG`, `CMOVG`, `SETG`
  Formatter_GetCC_g : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_g; cdecl = nil;

  // Mnemonic condition code selector ( eg. `JG` / `JNLE` )
  //
  // Default: `JG`, `CMOVG`, `SETG`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_g : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_g ) : boolean; cdecl = nil;


  // Encoder
  // Creates an encoder
  //
  // Returns NULL if `bitness` is not one of 16, 32, 64.
  //
  // # Arguments
  // * `bitness`: 16, 32 or 64
  // * `capacity`: Initial capacity of the `u8` buffer
  Encoder_Create : function( Bitness : Cardinal; Capacity : NativeUInt = 0 ) : Pointer; cdecl = nil;

  // Encodes an instruction and returns the size of the encoded instruction
  //
  // # Result
  // * Returns written amount of encoded Bytes
  //
  // # Arguments
  // * `instruction`: Instruction to encode
  // * `rip`: `RIP` of the encoded instruction
  Encoder_Encode : function( Encoder : Pointer; var Instruction : TInstruction ) : NativeUInt; cdecl = nil;

  // Writes a byte to the output buffer
  //
  // # Arguments
  //
  // `value`: Value to write
  Encoder_WriteByte : function ( Encoder : Pointer; Value : Byte ) : boolean; cdecl = nil;

  // Returns the buffer and initializes the internal buffer to an empty vector. Should be called when
  // you've encoded all instructions and need the raw instruction bytes. See also [`set_buffer()`].
  Encoder_GetBuffer : function ( Encoder : Pointer; Value : PByte; Size : NativeUInt ) : boolean; cdecl = nil;

  // Overwrites the buffer with a new vector. The old buffer is dropped. See also [`Encoder_GetBuffer`].
  // NOTE: Monitor the result of [`Encoder_Encode`] (Encoded Bytes).
  // DO NOT Encode more Bytes than fitting your provided Buffer as this would cause a realloc - which will lead to an access violation.
//  Encoder_SetBuffer : function ( Encoder : Pointer; Value : PByte; Size : NativeUInt ) : boolean; cdecl = nil;

  // Gets the offsets of the constants (memory displacement and immediate) in the encoded instruction.
  // The caller can use this information to add relocations if needed.
  Encoder_GetConstantOffsets : procedure( Decoder : Pointer; var ConstantOffsets : TConstantOffsets ); cdecl = nil;

  // Disables 2-byte VEX encoding and encodes all VEX instructions with the 3-byte VEX encoding
  Encoder_GetPreventVex2 : function( Encoder : Pointer ) : Boolean; cdecl = nil;

  // Disables 2-byte VEX encoding and encodes all VEX instructions with the 3-byte VEX encoding
  //
  // # Arguments
  // * `new_value`: new value
  Encoder_SetPreventVex2 : function ( Encoder : Pointer; Value : Boolean ) : boolean; cdecl = nil;

  // Value of the `VEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetVexWig : function( Encoder : Pointer ) : Cardinal; cdecl = nil;

  // Value of the `VEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetVexWig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl = nil;

  // Value of the `VEX.L` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetVexLig : function( Encoder : Pointer ) : Cardinal; cdecl = nil;

  // Value of the `VEX.L` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetVexLig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl = nil;

  // Value of the `EVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetEvexWig : function( Encoder : Pointer ) : Cardinal; cdecl = nil;

  // Value of the `EVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetEvexWig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl = nil;

  // Value of the `EVEX.L'L` bits to use if it's an instruction that ignores the bits. Default is 0.
  Encoder_GetEvexLig : function( Encoder : Pointer ) : Cardinal; cdecl = nil;

  // Value of the `EVEX.L'L` bits to use if it's an instruction that ignores the bits. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 3)
  Encoder_SetEvexLig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl = nil;

  // Value of the `MVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetMvexWig : function( Encoder : Pointer ) : Cardinal; cdecl = nil;

  // Value of the `MVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetMvexWig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl = nil;

  // Gets the bitness (16, 32 or 64)
  Encoder_GetBitness : function( Encoder : Pointer ) : Cardinal; cdecl = nil;

  // Encodes instructions. Any number of branches can be part of this block.
  // You can use this function to move instructions from one location to another location.
  // If the target of a branch is too far away, it'll be rewritten to a longer branch.
  // You can disable this by passing in [`BlockEncoderOptions::DONT_FIX_BRANCHES`].
  // If the block has any `RIP`-relative memory operands, make sure the data isn't too
  // far away from the new location of the encoded instructions. Every OS should have
  // some API to allocate memory close (+/-2GB) to the original code location.
  //
  // # Errors
  // Returns 0-Data if it failed to encode one or more instructions.
  //
  // # Arguments
  // * `bitness`: 16, 32, or 64
  // * `Instructions`: First Instruction to encode
  // * `Count`: Instruction-Count
  // * `Results`: Result-Structure
  // * `Options`: Encoder options, see [`TBlockEncoderOptions`]
  //
  // # Result
  // * Pointer to Result-Data. Musst be free'd using FreeMemory()
  BlockEncoder : function( Bitness : Cardinal; RIP : UInt64; var Instructions : TInstruction; Count : NativeUInt; var Result : TBlockEncoderResult; Options : Cardinal = beoNONE ) : Pointer; cdecl = nil;

  // Instruction
  // Gets the FPU status word's `TOP` increment and whether it's a conditional or unconditional push/pop
  // and whether `TOP` is written.
  Instruction_FPU_StackIncrementInfo : function( var Instruction : TInstruction; var Info : TFpuStackIncrementInfo ) : Boolean; cdecl = nil;

  // Instruction encoding, eg. Legacy, 3DNow!, VEX, EVEX, XOP
  Instruction_Encoding : function( var Instruction : TInstruction ) : TEncodingKind; cdecl = nil;

  // Gets the mnemonic, see also [`code()`]
  Instruction_Mnemonic : function( var Instruction : TInstruction ) : TMnemonic; cdecl = nil;

  // Gets the CPU or CPUID feature flags
  Instruction_CPUIDFeatures : function( var Instruction : TInstruction; var CPUIDFeatures : TCPUIDFeaturesArray ) : Boolean; cdecl = nil;

  // `true` if this is an instruction that implicitly uses the stack pointer (`SP`/`ESP`/`RSP`), eg. `CALL`, `PUSH`, `POP`, `RET`, etc.
  // See also [`stack_pointer_increment()`]
  //
  // [`stack_pointer_increment()`]: #method.stack_pointer_increment
  Instruction_IsStackInstruction : function( var Instruction : TInstruction ) : Boolean; cdecl = nil;

  // Gets the number of bytes added to `SP`/`ESP`/`RSP` or 0 if it's not an instruction that pushes or pops data. This method assumes
  // the instruction doesn't change the privilege level (eg. `IRET/D/Q`). If it's the `LEAVE` instruction, this method returns 0.
  Instruction_StackPointerIncrement : function( var Instruction : TInstruction ) : Integer; cdecl = nil;

  // Gets the condition code if it's `Jcc`, `SETcc`, `CMOVcc`, `LOOPcc` else [`ConditionCode::None`] is returned
  //
  // [`ConditionCode::None`]: enum.ConditionCode.html#variant.None
  Instruction_ConditionCode : function( var Instruction : TInstruction ) : TConditionCode; cdecl = nil;

  // All flags that are read by the CPU when executing the instruction.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsRead : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl = nil;

  // All flags that are written by the CPU, except those flags that are known to be undefined, always set or always cleared.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsWritten : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl = nil;

  // All flags that are always cleared by the CPU.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsCleared : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl = nil;

  // All flags that are always set by the CPU.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsSet : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl = nil;

  // All flags that are undefined after executing the instruction.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsUndefined : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl = nil;

  // All flags that are modified by the CPU. This is `rflags_written() + rflags_cleared() + rflags_set() + rflags_undefined()`. This method returns an [`RflagsBits`] value.
  Instruction_RFlagsModified : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl = nil;

  // Control flow info
  Instruction_FlowControl : function( var Instruction : TInstruction ) : TFlowControl; cdecl = nil;

  // Gets all op kinds ([`op_count()`] values)
  Instruction_OPKinds : function( var Instruction : TInstruction; var OPKindsArray : TOPKindsArray ) : TFlowControl; cdecl = nil;

  // Gets the size of the memory location that is referenced by the operand. See also [`is_broadcast()`].
  // Use this method if the operand has kind [`OpKind::Memory`],
  Instruction_MemorySize : function( var Instruction : TInstruction ) : Byte; cdecl = nil;

  // Gets the operand count. An instruction can have 0-5 operands.
  Instruction_OPCount : function( var Instruction : TInstruction ) : Cardinal; cdecl = nil;

  // OpCodeInfo
  // Gets the code
  Instruction_OpCodeInfo_Code : function( var Instruction : TInstruction ) : TCode; cdecl = nil;

  // Gets the mnemonic
  Instruction_OpCodeInfo_Mnemonic : function( var Instruction : TInstruction ) : TMnemonic; cdecl = nil;

  // `true` if it's an instruction, `false` if it's eg. [`Code::INVALID`], [`db`], [`dw`], [`dd`], [`dq`], [`zero_bytes`]
  Instruction_OpCodeInfo_IsInstruction : function( var Instruction : TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's an instruction available in 16-bit mode
  Instruction_OpCodeInfo_Mode16 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's an instruction available in 32-bit mode
  Instruction_OpCodeInfo_Mode32 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's an instruction available in 64-bit mode
  Instruction_OpCodeInfo_Mode64 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if an `FWAIT` (`9B`) instruction is added before the instruction
  Instruction_OpCodeInfo_Fwait : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (Legacy encoding) Gets the required operand size (16,32,64) or 0
  Instruction_OpCodeInfo_OperandSize : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // (Legacy encoding) Gets the required address size (16,32,64) or 0
  Instruction_OpCodeInfo_AddressSize : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // (VEX/XOP/EVEX) `L` / `L'L` value or default value if [`is_lig()`] is `true`
  Instruction_OpCodeInfo_L : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // (VEX/XOP/EVEX/MVEX) `W` value or default value if [`is_wig()`] or [`is_wig32()`] is `true`
  Instruction_OpCodeInfo_W : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // (VEX/XOP/EVEX) `true` if the `L` / `L'L` fields are ignored.
  //
  // EVEX: if reg-only ops and `{er}` (`EVEX.b` is set), `L'L` is the rounding control and not ignored.
  Instruction_OpCodeInfo_IsLig : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (VEX/XOP/EVEX/MVEX) `true` if the `W` field is ignored in 16/32/64-bit modes
  Instruction_OpCodeInfo_IsWig : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (VEX/XOP/EVEX/MVEX) `true` if the `W` field is ignored in 16/32-bit modes (but not 64-bit mode)
  Instruction_OpCodeInfo_IsWig32 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (EVEX/MVEX) Gets the tuple type
  Instruction_OpCodeInfo_TupleType : function( var Instruction: TInstruction ) : TTupleType; cdecl = nil;

  // (MVEX) Gets the `EH` bit that's required to encode this instruction
  Instruction_OpCodeInfo_MvexEhBit : function( var Instruction: TInstruction ) : TMvexEHBit; cdecl = nil;

  // (MVEX) `true` if the instruction supports eviction hint (if it has a memory operand)
  Instruction_OpCodeInfo_MvexCanUseEvictionHint : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (MVEX) `true` if the instruction's rounding control bits are stored in `imm8[1:0]`
  Instruction_OpCodeInfo_MvexCanUseImmRoundingControl : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (MVEX) `true` if the instruction ignores op mask registers (eg. `{k1}`)
  Instruction_OpCodeInfo_MvexIgnoresOpMaskRegister : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (MVEX) `true` if the instruction must have `MVEX.SSS=000` if `MVEX.EH=1`
  Instruction_OpCodeInfo_MvexNoSaeRc : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (MVEX) Gets the tuple type / conv lut kind
  Instruction_OpCodeInfo_MvexTupleTypeLutKind : function( var Instruction: TInstruction ) : TMvexTupleTypeLutKind; cdecl = nil;

  // (MVEX) Gets the conversion function, eg. `Sf32`
  Instruction_OpCodeInfo_MvexConversionFunc : function( var Instruction: TInstruction ) : TMvexConvFn; cdecl = nil;

  // (MVEX) Gets flags indicating which conversion functions are valid (bit 0 == func 0)
  Instruction_OpCodeInfo_MvexValidConversionFuncsMask : function( var Instruction: TInstruction ) : Byte; cdecl = nil;

  // (MVEX) Gets flags indicating which swizzle functions are valid (bit 0 == func 0)
  Instruction_OpCodeInfo_MvexValidSwizzleFuncsMask : function( var Instruction: TInstruction ) : Byte; cdecl = nil;

  // If it has a memory operand, gets the [`MemorySize`] (non-broadcast memory type)
  Instruction_OpCodeInfo_MemorySize : function( var Instruction: TInstruction ) : TMemorySize; cdecl = nil;

  // If it has a memory operand, gets the [`MemorySize`] (broadcast memory type)
  Instruction_OpCodeInfo_BroadcastMemorySize : function( var Instruction: TInstruction ) : TMemorySize; cdecl = nil;

  // (EVEX) `true` if the instruction supports broadcasting (`EVEX.b` bit) (if it has a memory operand)
  Instruction_OpCodeInfo_CanBroadcast : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (EVEX/MVEX) `true` if the instruction supports rounding control
  Instruction_OpCodeInfo_CanUseRoundingControl : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (EVEX/MVEX) `true` if the instruction supports suppress all exceptions
  Instruction_OpCodeInfo_CanSuppressAllExceptions : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (EVEX/MVEX) `true` if an opmask register can be used
  Instruction_OpCodeInfo_CanUseOpMaskRegister : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (EVEX/MVEX) `true` if a non-zero opmask register must be used
  Instruction_OpCodeInfo_RequireOpMaskRegister : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (EVEX) `true` if the instruction supports zeroing masking (if one of the opmask registers `K1`-`K7` is used and destination operand is not a memory operand)
  Instruction_OpCodeInfo_CanUseZeroingMasking : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `LOCK` (`F0`) prefix can be used
  Instruction_OpCodeInfo_CanUseLockPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `XACQUIRE` (`F2`) prefix can be used
  Instruction_OpCodeInfo_CanUseXacquirePrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `XRELEASE` (`F3`) prefix can be used
  Instruction_OpCodeInfo_CanUseXreleasePrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `REP` / `REPE` (`F3`) prefixes can be used
  Instruction_OpCodeInfo_CanUseRepPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `REPNE` (`F2`) prefix can be used
  Instruction_OpCodeInfo_CanUseRepnePrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `BND` (`F2`) prefix can be used
  Instruction_OpCodeInfo_CanUseBndPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `HINT-TAKEN` (`3E`) and `HINT-NOT-TAKEN` (`2E`) prefixes can be used
  Instruction_OpCodeInfo_CanUseHintTakenPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `NOTRACK` (`3E`) prefix can be used
  Instruction_OpCodeInfo_CanUseNotrackPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if rounding control is ignored (#UD is not generated)
  Instruction_OpCodeInfo_IgnoresRoundingControl : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `LOCK` prefix can be used as an extra register bit (bit 3) to access registers 8-15 without a `REX` prefix (eg. in 32-bit mode)
  Instruction_OpCodeInfo_AmdLockRegBit : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the default operand size is 64 in 64-bit mode. A `66` prefix can switch to 16-bit operand size.
  Instruction_OpCodeInfo_DefaultOpSize64 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the operand size is always 64 in 64-bit mode. A `66` prefix is ignored.
  Instruction_OpCodeInfo_ForceOpSize64 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the Intel decoder forces 64-bit operand size. A `66` prefix is ignored.
  Instruction_OpCodeInfo_IntelForceOpSize64 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can only be executed when CPL=0
  Instruction_OpCodeInfo_MustBeCpl0 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed when CPL=0
  Instruction_OpCodeInfo_Cpl0 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed when CPL=1
  Instruction_OpCodeInfo_Cpl1 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed when CPL=2
  Instruction_OpCodeInfo_Cpl2 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed when CPL=3
  Instruction_OpCodeInfo_Cpl3 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the instruction accesses the I/O address space (eg. `IN`, `OUT`, `INS`, `OUTS`)
  Instruction_OpCodeInfo_IsInputOutput : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's one of the many nop instructions (does not include FPU nop instructions, eg. `FNOP`)
  Instruction_OpCodeInfo_IsNop : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's one of the many reserved nop instructions (eg. `0F0D`, `0F18-0F1F`)
  Instruction_OpCodeInfo_IsReservedNop : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's a serializing instruction (Intel CPUs)
  Instruction_OpCodeInfo_IsSerializingIntel : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's a serializing instruction (AMD CPUs)
  Instruction_OpCodeInfo_IsSerializingAmd : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the instruction requires either CPL=0 or CPL<=3 depending on some CPU option (eg. `CR4.TSD`, `CR4.PCE`, `CR4.UMIP`)
  Instruction_OpCodeInfo_MayRequireCpl0 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's a tracked `JMP`/`CALL` indirect instruction (CET)
  Instruction_OpCodeInfo_IsCetTracked : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's a non-temporal hint memory access (eg. `MOVNTDQ`)
  Instruction_OpCodeInfo_IsNonTemporal : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's a no-wait FPU instruction, eg. `FNINIT`
  Instruction_OpCodeInfo_IsFpuNoWait : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the mod bits are ignored and it's assumed `modrm[7:6] == 11b`
  Instruction_OpCodeInfo_IgnoresModBits : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `66` prefix is not allowed (it will #UD)
  Instruction_OpCodeInfo_No66 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the `F2`/`F3` prefixes aren't allowed
  Instruction_OpCodeInfo_Nfx : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the index reg's reg-num (vsib op) (if any) and register ops' reg-nums must be unique,
  // eg. `MNEMONIC XMM1,YMM1,[RAX+ZMM1*2]` is invalid. Registers = `XMM`/`YMM`/`ZMM`/`TMM`.
  Instruction_OpCodeInfo_RequiresUniqueRegNums : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the destination register's reg-num must not be present in any other operand, eg. `MNEMONIC XMM1,YMM1,[RAX+ZMM1*2]`
  // is invalid. Registers = `XMM`/`YMM`/`ZMM`/`TMM`.
  Instruction_OpCodeInfo_RequiresUniqueDestRegNum : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's a privileged instruction (all CPL=0 instructions (except `VMCALL`) and IOPL instructions `IN`, `INS`, `OUT`, `OUTS`, `CLI`, `STI`)
  Instruction_OpCodeInfo_IsPrivileged : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it reads/writes too many registers
  Instruction_OpCodeInfo_IsSaveRestore : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's an instruction that implicitly uses the stack register, eg. `CALL`, `POP`, etc
  Instruction_OpCodeInfo_IsStackInstruction : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the instruction doesn't read the segment register if it uses a memory operand
  Instruction_OpCodeInfo_IgnoresSegment : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if the opmask register is read and written (instead of just read). This also implies that it can't be `K0`.
  Instruction_OpCodeInfo_IsOpMaskReadWrite : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed in real mode
  Instruction_OpCodeInfo_RealMode : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed in protected mode
  Instruction_OpCodeInfo_ProtectedMode : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed in virtual 8086 mode
  Instruction_OpCodeInfo_Virtual8086Mode : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed in compatibility mode
  Instruction_OpCodeInfo_CompatibilityMode : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be executed in 64-bit mode
  Instruction_OpCodeInfo_LongMode : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used outside SMM
  Instruction_OpCodeInfo_UseOutsideSmm : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used in SMM
  Instruction_OpCodeInfo_UseInSmm : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used outside an enclave (SGX)
  Instruction_OpCodeInfo_UseOutsideEnclaveSgx : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used inside an enclave (SGX1)
  Instruction_OpCodeInfo_UseInEnclaveSgx1 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used inside an enclave (SGX2)
  Instruction_OpCodeInfo_UseInEnclaveSgx2 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used outside VMX operation
  Instruction_OpCodeInfo_UseOutsideVmxOp : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used in VMX root operation
  Instruction_OpCodeInfo_UseInVmxRootOp : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used in VMX non-root operation
  Instruction_OpCodeInfo_UseInVmxNonRootOp : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used outside SEAM
  Instruction_OpCodeInfo_UseOutsideSeam : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it can be used in SEAM
  Instruction_OpCodeInfo_UseInSeam : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if #UD is generated in TDX non-root operation
  Instruction_OpCodeInfo_TdxNonRootGenUd : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if #VE is generated in TDX non-root operation
  Instruction_OpCodeInfo_TdxNonRootGenVe : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if an exception (eg. #GP(0), #VE) may be generated in TDX non-root operation
  Instruction_OpCodeInfo_TdxNonRootMayGenEx : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (Intel VMX) `true` if it causes a VM exit in VMX non-root operation
  Instruction_OpCodeInfo_IntelVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (Intel VMX) `true` if it may cause a VM exit in VMX non-root operation
  Instruction_OpCodeInfo_IntelMayVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (Intel VMX) `true` if it causes an SMM VM exit in VMX root operation (if dual-monitor treatment is activated)
  Instruction_OpCodeInfo_IntelSmmVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (AMD SVM) `true` if it causes a #VMEXIT in guest mode
  Instruction_OpCodeInfo_AmdVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // (AMD SVM) `true` if it may cause a #VMEXIT in guest mode
  Instruction_OpCodeInfo_AmdMayVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it causes a TSX abort inside a TSX transaction
  Instruction_OpCodeInfo_TsxAbort : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it causes a TSX abort inside a TSX transaction depending on the implementation
  Instruction_OpCodeInfo_TsxImplAbort : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it may cause a TSX abort inside a TSX transaction depending on some condition
  Instruction_OpCodeInfo_TsxMayAbort : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's decoded by iced's 16-bit Intel decoder
  Instruction_OpCodeInfo_IntelDecoder16 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's decoded by iced's 32-bit Intel decoder
  Instruction_OpCodeInfo_IntelDecoder32 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's decoded by iced's 64-bit Intel decoder
  Instruction_OpCodeInfo_IntelDecoder64 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's decoded by iced's 16-bit AMD decoder
  Instruction_OpCodeInfo_AmdDecoder16 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's decoded by iced's 32-bit AMD decoder
  Instruction_OpCodeInfo_AmdDecoder32 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // `true` if it's decoded by iced's 64-bit AMD decoder
  Instruction_OpCodeInfo_AmdDecoder64 : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // Gets the decoder option that's needed to decode the instruction or [`DecoderOptions::NONE`].
  // The return value is a [`DecoderOptions`] value.
  Instruction_OpCodeInfo_DecoderOption : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // Gets the opcode table
  Instruction_OpCodeInfo_Table : function( var Instruction: TInstruction ) : TOpCodeTableKind; cdecl = nil;

  // Gets the mandatory prefix
  Instruction_OpCodeInfo_MandatoryPrefix : function( var Instruction: TInstruction ) : TMandatoryPrefix; cdecl = nil;

  // Gets the opcode byte(s). The low byte(s) of this value is the opcode. The length is in [`op_code_len()`].
  // It doesn't include the table value, see [`table()`].
  Instruction_OpCodeInfo_OpCode : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // Gets the length of the opcode bytes ([`op_code()`]). The low bytes is the opcode value.
  Instruction_OpCodeInfo_OpCodeLen : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // `true` if it's part of a group
  Instruction_OpCodeInfo_IsGroup : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // Group index (0-7) or -1. If it's 0-7, it's stored in the `reg` field of the `modrm` byte.
  Instruction_OpCodeInfo_GroupIndex : function( var Instruction: TInstruction ) : Integer; cdecl = nil;

  // `true` if it's part of a modrm.rm group
  Instruction_OpCodeInfo_IsRMGroup : function( var Instruction: TInstruction ) : Boolean; cdecl = nil;

  // Group index (0-7) or -1. If it's 0-7, it's stored in the `rm` field of the `modrm` byte.
  Instruction_OpCodeInfo_RMGroupIndex : function( var Instruction: TInstruction ) : Integer; cdecl = nil;

  // Gets the number of operands
  Instruction_OpCodeInfo_OPCount : function( var Instruction: TInstruction ) : Cardinal; cdecl = nil;

  // Gets operand #0's opkind
  Instruction_OpCodeInfo_OP0Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl = nil;

  // Gets operand #1's opkind
  Instruction_OpCodeInfo_OP1Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl = nil;

  // Gets operand #2's opkind
  Instruction_OpCodeInfo_OP2Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl = nil;

  // Gets operand #3's opkind
  Instruction_OpCodeInfo_OP3Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl = nil;

  // Gets operand #4's opkind
  Instruction_OpCodeInfo_OP4Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl = nil;

  // Gets an operand's opkind
  //
  // # Arguments
  //
  // * `operand`: Operand number, 0-4
  Instruction_OpCodeInfo_OPKind : function( var Instruction: TInstruction; operand: Cardinal ) : TOpCodeOperandKind; cdecl = nil;

  // Gets all operand kinds
  Instruction_OpCodeInfo_OPKinds : function( var Instruction: TInstruction; var OPKinds : TOPCodeOperandKindArray ) : Boolean; cdecl = nil;

  // Checks if the instruction is available in 16-bit mode, 32-bit mode or 64-bit mode
  //
  // # Arguments
  //
  // * `bitness`: 16, 32 or 64
  Instruction_OpCodeInfo_IsAvailableInMode : function( var Instruction: TInstruction; Bitness: Cardinal ) : Boolean; cdecl = nil;

  // Gets the opcode string, eg. `VEX.128.66.0F38.W0 78 /r`, see also [`instruction_string()`]
  Instruction_OpCodeInfo_OpCodeString : function( var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ) : Boolean; cdecl = nil;

  // Gets the instruction string, eg. `VPBROADCASTB xmm1, xmm2/m8`, see also [`op_code_string()`]
  Instruction_OpCodeInfo_InstructionString : function( var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ) : Boolean; cdecl = nil;

  // Virtual-Address Resolver
  // Gets the virtual address of a memory operand
  //
  // # Arguments
  // * `operand`: Operand number, 0-4, must be a memory operand
  // * `element_index`: Only used if it's a vsib memory operand. This is the element index of the vector index register.
  // * `get_register_value`: Function that returns the value of a register or the base address of a segment register, or `None` for unsupported
  //    registers.
  //
  // # Call-back function args
  // * Arg 1: `register`: Register (GPR8, GPR16, GPR32, GPR64, XMM, YMM, ZMM, seg). If it's a segment register, the call-back function should return the segment's base address, not the segment's register value.
  // * Arg 2: `element_index`: Only used if it's a vsib memory operand. This is the element index of the vector index register.
  // * Arg 3: `element_size`: Only used if it's a vsib memory operand. Size in bytes of elements in vector index register (4 or 8).
  Instruction_VirtualAddress : function ( var Instruction: TInstruction; Callback : TVirtualAddressResolverCallback; Operand : Cardinal = 0; Index : NativeUInt = 0; UserData : Pointer = nil ) : UInt64; cdecl = nil;

  // InstructionInfoFactory
  // Creates a new instance.
  //
  // If you don't need to know register and memory usage, it's faster to call [`Instruction`] and
  // [`Code`] methods such as [`Instruction::flow_control()`] instead of getting that info from this struct.
  //
  // [`Instruction`]: struct.Instruction.html
  // [`Code`]: enum.Code.html
  // [`Instruction::flow_control()`]: struct.Instruction.html#method.flow_control
  InstructionInfoFactory_Create : function : Pointer; cdecl = nil;

  // Creates a new [`InstructionInfo`], see also [`info()`].
  //
  // If you don't need to know register and memory usage, it's faster to call [`Instruction`] and
  // [`Code`] methods such as [`Instruction::flow_control()`] instead of getting that info from this struct.
  InstructionInfoFactory_Info : function( InstructionInfoFactory : Pointer; var Instruction: TInstruction; var InstructionInfo : TInstructionInfo; Options : Cardinal = iioNone ) : Boolean; cdecl = nil;

  // Instruction 'WITH'
  // Creates an instruction with no operands
  Instruction_With : function( var Instruction : TInstruction; Code : TCode ) : Boolean; cdecl = nil;

  // Creates an instruction with 1 operand
  //
  // # Errors
  // Fails if one of the operands is invalid (basic checks)
  Instruction_With1_Register : function( var Instruction : TInstruction; Code : TCode; Register : TRegister ) : Boolean; cdecl = nil;
  Instruction_With1_i32 : function( var Instruction : TInstruction; Code : TCode; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With1_u32 : function( var Instruction : TInstruction; Code : TCode; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With1_Memory : function( var Instruction : TInstruction; Code : TCode; var Memory : TMemoryOperand ) : Boolean; cdecl = nil;
  Instruction_With2_Register_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister ) : Boolean; cdecl = nil;
  Instruction_With2_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With2_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With2_Register_i64 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : Int64 ) : Boolean; cdecl = nil;
  Instruction_With2_Register_u64 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : UInt64 ) : Boolean; cdecl = nil;
  Instruction_With2_Register_MemoryOperand : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; var Memory : TMemoryOperand ) : Boolean; cdecl = nil;
  Instruction_With2_i32_Register : function( var Instruction : TInstruction; Code : TCode; Immediate : Integer; Register : TRegister ) : Boolean; cdecl = nil;
  Instruction_With2_u32_Register : function( var Instruction : TInstruction; Code : TCode; Immediate : Cardinal; Register : TRegister ) : Boolean; cdecl = nil;
  Instruction_With2_i32_i32 : function( var Instruction : TInstruction; Code : TCode; Immediate1 : Integer; Immediate2 : Integer ) : Boolean; cdecl = nil;
  Instruction_With2_u32_u32 : function( var Instruction : TInstruction; Code : TCode; Immediate1 : Cardinal; Immediate2 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With2_MemoryOperand_Register : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register : TRegister ) : Boolean; cdecl = nil;
  Instruction_With2_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With2_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With3_Register_Register_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister ) : Boolean; cdecl = nil;
  Instruction_With3_Register_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With3_Register_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With3_Register_Register_MemoryOperand : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; var Memory : TMemoryOperand ) : Boolean; cdecl = nil;
  Instruction_With3_Register_i32_i32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : Boolean; cdecl = nil;
  Instruction_With3_Register_u32_u32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With3_Register_MemoryOperand_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Register2 : TRegister ) : Boolean; cdecl = nil;
  Instruction_With3_Register_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With3_Register_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With3_MemoryOperand_Register_Register : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register1 : TRegister; Register2 : TRegister ) : Boolean; cdecl = nil;
  Instruction_With3_MemoryOperand_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register : TRegister; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With3_MemoryOperand_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register : TRegister; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_Register_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_Register_MemoryOperand : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; var Memory : TMemoryOperand ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_i32_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_u32_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_MemoryOperand_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With4_Register_Register_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With5_Register_Register_Register_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With5_Register_Register_Register_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With5_Register_Register_Register_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With5_Register_Register_Register_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With5_Register_Register_MemoryOperand_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Integer ) : Boolean; cdecl = nil;
  Instruction_With5_Register_Register_MemoryOperand_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Branch : function( var Instruction : TInstruction; Code : TCode; Target : UInt64 ) : Boolean; cdecl = nil;
  Instruction_With_Far_Branch : function( var Instruction : TInstruction; Code : TCode; Selector : Word; Offset : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_xbegin : function( var Instruction : TInstruction; Bitness : Cardinal; Target : UInt64 ) : Boolean; cdecl = nil;
  Instruction_With_outsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_outsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_outsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_outsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_outsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_outsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_lodsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_lodsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_lodsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_lodsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_lodsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_lodsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_lodsq : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_lodsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_scasb : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_scasb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_scasb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_scasw : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_scasw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_scasw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_scasd : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_scasd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_scasd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_scasq : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_scasq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_scasq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_insb : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_insb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_insw : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_insw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_insd : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_insd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_stosb : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_stosb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_stosw : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_stosw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_stosd : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_stosd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_stosq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_cmpsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_cmpsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_cmpsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_cmpsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_cmpsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_cmpsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_cmpsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_cmpsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_cmpsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_cmpsq : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repe_cmpsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Repne_cmpsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_movsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_movsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_movsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_movsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_movsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_movsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_movsq : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Rep_movsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_maskmovq : function( var Instruction : TInstruction; AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_maskmovdqu : function( var Instruction : TInstruction; AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_vmaskmovdqu : function( var Instruction : TInstruction; AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_1 : function( var Instruction : TInstruction; B0 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_2 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_3 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_4 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_5 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_6 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_7 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_8 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_9 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_10 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_11 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_12 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_13 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_14 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_15 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Byte_16 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte; B15 : Byte ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_1 : function( var Instruction : TInstruction; W0 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_2 : function( var Instruction : TInstruction; W0 : Word; W1 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_3 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_4 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_5 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_6 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_7 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_Word_8 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word; W7 : Word ) : Boolean; cdecl = nil;
  Instruction_With_Declare_DWord_1 : function( var Instruction : TInstruction; D0 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Declare_DWord_2 : function( var Instruction : TInstruction; D0 : Cardinal; D1 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Declare_DWord_3 : function( var Instruction : TInstruction; D0 : Cardinal; D1 : Cardinal; D2 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Declare_DWord_4 : function( var Instruction : TInstruction; D0 : Cardinal; D1 : Cardinal; D2 : Cardinal; D3 : Cardinal ) : Boolean; cdecl = nil;
  Instruction_With_Declare_QWord_1 : function( var Instruction : TInstruction; Q0 : UInt64 ) : Boolean; cdecl = nil;
  Instruction_With_Declare_QWord_2 : function( var Instruction : TInstruction; Q0 : UInt64; Q1 : UInt64 ) : Boolean; cdecl = nil;

{$WARNINGS ON}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

implementation

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$DEFINE section_IMPLEMENTATION_USES}
{$I DynamicDLL.inc}
{$UNDEF section_IMPLEMENTATION_USES}
;

{$DEFINE section_IMPLEMENTATION_INITVAR}
{$I DynamicDLL.inc}
{$UNDEF section_IMPLEMENTATION_INITVAR}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
procedure PreInitialization;
begin
  // Code needed before Init, likely change DLL OS-Dependent
end;

procedure InitDLL( ID : Byte; StrL : TStringList );
begin
  {$DEFINE section_InitVar}
  {$WARNINGS OFF}

  case ID of
    0 : begin
        InitVar( @IcedFreeMemory, 'IcedFreeMemory', ID, StrL );

        // Decoder
        InitVar( @Decoder_Create,  'Decoder_Create', ID, StrL );
        InitVar( @Decoder_CanDecode, 'Decoder_CanDecode', ID, StrL );
        InitVar( @Decoder_GetIP, 'Decoder_GetIP', ID, StrL );
        InitVar( @Decoder_SetIP, 'Decoder_SetIP', ID, StrL );
        InitVar( @Decoder_GetBitness, 'Decoder_GetBitness', ID, StrL );
        InitVar( @Decoder_GetMaxPosition, 'Decoder_GetMaxPosition', ID, StrL );
        InitVar( @Decoder_GetPosition, 'Decoder_GetPosition', ID, StrL );
        InitVar( @Decoder_SetPosition, 'Decoder_SetPosition', ID, StrL );
        InitVar( @Decoder_GetLastError, 'Decoder_GetLastError', ID, StrL );
        InitVar( @Decoder_Decode, 'Decoder_Decode', ID, StrL );
        InitVar( @Decoder_GetConstantOffsets, 'Decoder_GetConstantOffsets', ID, StrL );

        InitVar( @FormatterOutput_Create, 'FormatterOutput_Create', ID, StrL );

        // MasmFormatter
        InitVar( @MasmFormatter_Create, 'MasmFormatter_Create', ID, StrL );
        InitVar( @MasmFormatter_Format, 'MasmFormatter_Format', ID, StrL );
        InitVar( @MasmFormatter_FormatCallback, 'MasmFormatter_FormatCallback', ID, StrL );

        // NasmFormatter
        InitVar( @NasmFormatter_Create, 'NasmFormatter_Create', ID, StrL );
        InitVar( @NasmFormatter_Format, 'NasmFormatter_Format', ID, StrL );
        InitVar( @NasmFormatter_FormatCallback, 'NasmFormatter_FormatCallback', ID, StrL );

        // GasFormatter
        InitVar( @GasFormatter_Create, 'GasFormatter_Create', ID, StrL );
        InitVar( @GasFormatter_Format, 'GasFormatter_Format', ID, StrL );
        InitVar( @GasFormatter_FormatCallback, 'GasFormatter_FormatCallback', ID, StrL );

        // IntelFormatter
        InitVar( @IntelFormatter_Create, 'IntelFormatter_Create', ID, StrL );
        InitVar( @IntelFormatter_Format, 'IntelFormatter_Format', ID, StrL );
        InitVar( @IntelFormatter_FormatCallback, 'IntelFormatter_FormatCallback', ID, StrL );

        // FastFormatter
        InitVar( @FastFormatter_Create, 'FastFormatter_Create', ID, StrL );
        InitVar( @FastFormatter_Format, 'FastFormatter_Format', ID, StrL );

        // SpecializedFormatter
        InitVar( @SpecializedFormatter_Create, 'SpecializedFormatter_Create', ID, StrL );
        InitVar( @SpecializedFormatter_Format, 'SpecializedFormatter_Format', ID, StrL );
        // Options
        InitVar( @SpecializedFormatter_GetAlwaysShowMemorySize, 'SpecializedFormatter_GetAlwaysShowMemorySize', ID, StrL );
        InitVar( @SpecializedFormatter_SetAlwaysShowMemorySize, 'SpecializedFormatter_SetAlwaysShowMemorySize', ID, StrL );
        InitVar( @SpecializedFormatter_GetUseHexPrefix, 'SpecializedFormatter_GetUseHexPrefix', ID, StrL );
        InitVar( @SpecializedFormatter_SetUseHexPrefix, 'SpecializedFormatter_SetUseHexPrefix', ID, StrL );

        // Formatter Options
        InitVar( @Formatter_Format, 'Formatter_Format', ID, StrL );
        InitVar( @Formatter_FormatCallback, 'Formatter_FormatCallback', ID, StrL );

        InitVar( @Formatter_GetUpperCasePrefixes, 'Formatter_GetUpperCasePrefixes', ID, StrL );
        InitVar( @Formatter_SetUpperCasePrefixes, 'Formatter_SetUpperCasePrefixes', ID, StrL );
        InitVar( @Formatter_GetUpperCaseMnemonics, 'Formatter_GetUpperCaseMnemonics', ID, StrL );
        InitVar( @Formatter_SetUpperCaseMnemonics, 'Formatter_SetUpperCaseMnemonics', ID, StrL );
        InitVar( @Formatter_GetUpperCaseRegisters, 'Formatter_GetUpperCaseRegisters', ID, StrL );
        InitVar( @Formatter_SetUpperCaseRegisters, 'Formatter_SetUpperCaseRegisters', ID, StrL );
        InitVar( @Formatter_GetUpperCaseKeyWords, 'Formatter_GetUpperCaseKeyWords', ID, StrL );
        InitVar( @Formatter_SetUpperCaseKeyWords, 'Formatter_SetUpperCaseKeyWords', ID, StrL );
        InitVar( @Formatter_GetUpperCaseDecorators, 'Formatter_GetUpperCaseDecorators', ID, StrL );
        InitVar( @Formatter_SetUpperCaseDecorators, 'Formatter_SetUpperCaseDecorators', ID, StrL );
        InitVar( @Formatter_GetUpperCaseEverything, 'Formatter_GetUpperCaseEverything', ID, StrL );
        InitVar( @Formatter_SetUpperCaseEverything, 'Formatter_SetUpperCaseEverything', ID, StrL );
        InitVar( @Formatter_GetFirstOperandCharIndex, 'Formatter_GetFirstOperandCharIndex', ID, StrL );
        InitVar( @Formatter_SetFirstOperandCharIndex, 'Formatter_SetFirstOperandCharIndex', ID, StrL );
        InitVar( @Formatter_GetTabSize, 'Formatter_GetTabSize', ID, StrL );
        InitVar( @Formatter_SetTabSize, 'Formatter_SetTabSize', ID, StrL );
        InitVar( @Formatter_GetSpaceAfterOperandSeparator, 'Formatter_GetSpaceAfterOperandSeparator', ID, StrL );
        InitVar( @Formatter_SetSpaceAfterOperandSeparator, 'Formatter_SetSpaceAfterOperandSeparator', ID, StrL );
        InitVar( @Formatter_GetSpaceAfterMemoryBracket, 'Formatter_GetSpaceAfterMemoryBracket', ID, StrL );
        InitVar( @Formatter_SetSpaceAfterMemoryBracket, 'Formatter_SetSpaceAfterMemoryBracket', ID, StrL );
        InitVar( @Formatter_GetSpaceBetweenMemoryAddOperators, 'Formatter_GetSpaceBetweenMemoryAddOperators', ID, StrL );
        InitVar( @Formatter_SetSpaceBetweenMemoryAddOperators, 'Formatter_SetSpaceBetweenMemoryAddOperators', ID, StrL );
        InitVar( @Formatter_GetSpaceBetweenMemoryMulOperators, 'Formatter_GetSpaceBetweenMemoryMulOperators', ID, StrL );
        InitVar( @Formatter_SetSpaceBetweenMemoryMulOperators, 'Formatter_SetSpaceBetweenMemoryMulOperators', ID, StrL );
        InitVar( @Formatter_GetScaleBeforeIndex, 'Formatter_GetScaleBeforeIndex', ID, StrL );
        InitVar( @Formatter_SetScaleBeforeIndex, 'Formatter_SetScaleBeforeIndex', ID, StrL );
        InitVar( @Formatter_GetAlwaysShowScale, 'Formatter_GetAlwaysShowScale', ID, StrL );
        InitVar( @Formatter_SetAlwaysShowScale, 'Formatter_SetAlwaysShowScale', ID, StrL );
        InitVar( @Formatter_GetAlwaysShowSegmentRegister, 'Formatter_GetAlwaysShowSegmentRegister', ID, StrL );
        InitVar( @Formatter_SetAlwaysShowSegmentRegister, 'Formatter_SetAlwaysShowSegmentRegister', ID, StrL );
        InitVar( @Formatter_GetShowZeroDisplacements, 'Formatter_GetShowZeroDisplacements', ID, StrL );
        InitVar( @Formatter_SetShowZeroDisplacements, 'Formatter_SetShowZeroDisplacements', ID, StrL );
        InitVar( @Formatter_GetHexPrefix, 'Formatter_GetHexPrefix', ID, StrL );
        InitVar( @Formatter_SetHexPrefix, 'Formatter_SetHexPrefix', ID, StrL );
        InitVar( @Formatter_GetHexSuffix, 'Formatter_GetHexSuffix', ID, StrL );
        InitVar( @Formatter_SetHexSuffix, 'Formatter_SetHexSuffix', ID, StrL );
        InitVar( @Formatter_GetHexDigitGroupSize, 'Formatter_GetHexDigitGroupSize', ID, StrL );
        InitVar( @Formatter_SetHexDigitGroupSize, 'Formatter_SetHexDigitGroupSize', ID, StrL );
        InitVar( @Formatter_GetDecimalPrefix, 'Formatter_GetDecimalPrefix', ID, StrL );
        InitVar( @Formatter_SetDecimalPrefix, 'Formatter_SetDecimalPrefix', ID, StrL );
        InitVar( @Formatter_GetDecimalSuffix, 'Formatter_GetDecimalSuffix', ID, StrL );
        InitVar( @Formatter_SetDecimalSuffix, 'Formatter_SetDecimalSuffix', ID, StrL );
        InitVar( @Formatter_GetDecimalDigitGroupSize, 'Formatter_GetDecimalDigitGroupSize', ID, StrL );
        InitVar( @Formatter_SetDecimalDigitGroupSize, 'Formatter_SetDecimalDigitGroupSize', ID, StrL );
        InitVar( @Formatter_GetOctalPrefix, 'Formatter_GetOctalPrefix', ID, StrL );
        InitVar( @Formatter_SetOctalPrefix, 'Formatter_SetOctalPrefix', ID, StrL );
        InitVar( @Formatter_GetOctalSuffix, 'Formatter_GetOctalSuffix', ID, StrL );
        InitVar( @Formatter_SetOctalSuffix, 'Formatter_SetOctalSuffix', ID, StrL );
        InitVar( @Formatter_GetOctalDigitGroupSize, 'Formatter_GetOctalDigitGroupSize', ID, StrL );
        InitVar( @Formatter_SetOctalDigitGroupSize, 'Formatter_SetOctalDigitGroupSize', ID, StrL );
        InitVar( @Formatter_GetBinaryPrefix, 'Formatter_GetBinaryPrefix', ID, StrL );
        InitVar( @Formatter_SetBinaryPrefix, 'Formatter_SetBinaryPrefix', ID, StrL );
        InitVar( @Formatter_GetBinarySuffix, 'Formatter_GetBinarySuffix', ID, StrL );
        InitVar( @Formatter_SetBinarySuffix, 'Formatter_SetBinarySuffix', ID, StrL );
        InitVar( @Formatter_GetBinaryDigitGroupSize, 'Formatter_GetBinaryDigitGroupSize', ID, StrL );
        InitVar( @Formatter_SetBinaryDigitGroupSize, 'Formatter_SetBinaryDigitGroupSize', ID, StrL );
        InitVar( @Formatter_GetDigitSeparator, 'Formatter_GetDigitSeparator', ID, StrL );
        InitVar( @Formatter_SetDigitSeparator, 'Formatter_SetDigitSeparator', ID, StrL );
        InitVar( @Formatter_GetLeadingZeros, 'Formatter_GetLeadingZeros', ID, StrL );
        InitVar( @Formatter_SetLeadingZeros, 'Formatter_SetLeadingZeros', ID, StrL );
        InitVar( @Formatter_GetUppercaseHex, 'Formatter_GetUppercaseHex', ID, StrL );
        InitVar( @Formatter_SetUppercaseHex, 'Formatter_SetUppercaseHex', ID, StrL );
        InitVar( @Formatter_GetSmallHexNumbersInDecimal, 'Formatter_GetSmallHexNumbersInDecimal', ID, StrL );
        InitVar( @Formatter_SetSmallHexNumbersInDecimal, 'Formatter_SetSmallHexNumbersInDecimal', ID, StrL );
        InitVar( @Formatter_GetAddLeadingZeroToHexNumbers, 'Formatter_GetAddLeadingZeroToHexNumbers', ID, StrL );
        InitVar( @Formatter_SetAddLeadingZeroToHexNumbers, 'Formatter_SetAddLeadingZeroToHexNumbers', ID, StrL );
        InitVar( @Formatter_GetNumberBase, 'Formatter_GetNumberBase', ID, StrL );
        InitVar( @Formatter_SetNumberBase, 'Formatter_SetNumberBase', ID, StrL );
        InitVar( @Formatter_GetBranchLeadingZeros, 'Formatter_GetBranchLeadingZeros', ID, StrL );
        InitVar( @Formatter_SetBranchLeadingZeros, 'Formatter_SetBranchLeadingZeros', ID, StrL );
        InitVar( @Formatter_GetSignedImmediateOperands, 'Formatter_GetSignedImmediateOperands', ID, StrL );
        InitVar( @Formatter_SetSignedImmediateOperands, 'Formatter_SetSignedImmediateOperands', ID, StrL );
        InitVar( @Formatter_GetSignedMemoryDisplacements, 'Formatter_GetSignedMemoryDisplacements', ID, StrL );
        InitVar( @Formatter_SetSignedMemoryDisplacements, 'Formatter_SetSignedMemoryDisplacements', ID, StrL );
        InitVar( @Formatter_GetDisplacementLeadingZeros, 'Formatter_GetDisplacementLeadingZeros', ID, StrL );
        InitVar( @Formatter_SetDisplacementLeadingZeros, 'Formatter_SetDisplacementLeadingZeros', ID, StrL );
        InitVar( @Formatter_GetMemorySizeOptions, 'Formatter_GetMemorySizeOptions', ID, StrL );
        InitVar( @Formatter_SetMemorySizeOptions, 'Formatter_SetMemorySizeOptions', ID, StrL );
        InitVar( @Formatter_GetRipRelativeAddresses, 'Formatter_GetRipRelativeAddresses', ID, StrL );
        InitVar( @Formatter_SetRipRelativeAddresses, 'Formatter_SetRipRelativeAddresses', ID, StrL );
        InitVar( @Formatter_GetShowBranchSize, 'Formatter_GetShowBranchSize', ID, StrL );
        InitVar( @Formatter_SetShowBranchSize, 'Formatter_SetShowBranchSize', ID, StrL );
        InitVar( @Formatter_GetUsePseudoOps, 'Formatter_GetUsePseudoOps', ID, StrL );
        InitVar( @Formatter_SetUsePseudoOps, 'Formatter_SetUsePseudoOps', ID, StrL );
        InitVar( @Formatter_GetShowSymbolAddress, 'Formatter_GetShowSymbolAddress', ID, StrL );
        InitVar( @Formatter_SetShowSymbolAddress, 'Formatter_SetShowSymbolAddress', ID, StrL );
        InitVar( @GasFormatter_GetNakedRegisters, 'GasFormatter_GetNakedRegisters', ID, StrL );
        InitVar( @GasFormatter_SetNakedRegisters, 'GasFormatter_SetNakedRegisters', ID, StrL );
        InitVar( @GasFormatter_GetShowMnemonicSizeSuffix, 'GasFormatter_GetShowMnemonicSizeSuffix', ID, StrL );
        InitVar( @GasFormatter_SetShowMnemonicSizeSuffix, 'GasFormatter_SetShowMnemonicSizeSuffix', ID, StrL );
        InitVar( @GasFormatter_GetSpaceAfterMemoryOperandComma, 'GasFormatter_GetSpaceAfterMemoryOperandComma', ID, StrL );
        InitVar( @GasFormatter_SetSpaceAfterMemoryOperandComma, 'GasFormatter_SetSpaceAfterMemoryOperandComma', ID, StrL );
        InitVar( @MasmFormatter_GetAddDsPrefix32, 'MasmFormatter_GetAddDsPrefix32', ID, StrL );
        InitVar( @MasmFormatter_SetAddDsPrefix32, 'MasmFormatter_SetAddDsPrefix32', ID, StrL );
        InitVar( @MasmFormatter_GetSymbolDisplacementInBrackets, 'MasmFormatter_GetSymbolDisplacementInBrackets', ID, StrL );
        InitVar( @MasmFormatter_SetSymbolDisplacementInBrackets, 'MasmFormatter_SetSymbolDisplacementInBrackets', ID, StrL );
        InitVar( @MasmFormatter_GetDisplacementInBrackets, 'MasmFormatter_GetDisplacementInBrackets', ID, StrL );
        InitVar( @MasmFormatter_SetDisplacementInBrackets, 'MasmFormatter_SetDisplacementInBrackets', ID, StrL );
        InitVar( @NasmFormatter_GetShowSignExtendedImmediateSize, 'NasmFormatter_GetShowSignExtendedImmediateSize', ID, StrL );
        InitVar( @NasmFormatter_SetShowSignExtendedImmediateSize, 'NasmFormatter_SetShowSignExtendedImmediateSize', ID, StrL );
        InitVar( @Formatter_GetPreferST0, 'Formatter_GetPreferST0', ID, StrL );
        InitVar( @Formatter_SetPreferST0, 'Formatter_SetPreferST0', ID, StrL );
        InitVar( @Formatter_GetShowUselessPrefixes, 'Formatter_GetShowUselessPrefixes', ID, StrL );
        InitVar( @Formatter_SetShowUselessPrefixes, 'Formatter_SetShowUselessPrefixes', ID, StrL );
        InitVar( @Formatter_GetCC_b, 'Formatter_GetCC_b', ID, StrL );
        InitVar( @Formatter_SetCC_b, 'Formatter_SetCC_b', ID, StrL );
        InitVar( @Formatter_GetCC_ae, 'Formatter_GetCC_ae', ID, StrL );
        InitVar( @Formatter_SetCC_ae, 'Formatter_SetCC_ae', ID, StrL );
        InitVar( @Formatter_GetCC_e, 'Formatter_GetCC_e', ID, StrL );
        InitVar( @Formatter_SetCC_e, 'Formatter_SetCC_e', ID, StrL );
        InitVar( @Formatter_GetCC_ne, 'Formatter_GetCC_ne', ID, StrL );
        InitVar( @Formatter_SetCC_ne, 'Formatter_SetCC_ne', ID, StrL );
        InitVar( @Formatter_GetCC_be, 'Formatter_GetCC_be', ID, StrL );
        InitVar( @Formatter_SetCC_be, 'Formatter_SetCC_be', ID, StrL );
        InitVar( @Formatter_GetCC_a, 'Formatter_GetCC_a', ID, StrL );
        InitVar( @Formatter_SetCC_a, 'Formatter_SetCC_a', ID, StrL );
        InitVar( @Formatter_GetCC_p, 'Formatter_GetCC_p', ID, StrL );
        InitVar( @Formatter_SetCC_p, 'Formatter_SetCC_p', ID, StrL );
        InitVar( @Formatter_GetCC_np, 'Formatter_GetCC_np', ID, StrL );
        InitVar( @Formatter_SetCC_np, 'Formatter_SetCC_np', ID, StrL );
        InitVar( @Formatter_GetCC_l, 'Formatter_GetCC_l', ID, StrL );
        InitVar( @Formatter_SetCC_l, 'Formatter_SetCC_l', ID, StrL );
        InitVar( @Formatter_GetCC_ge, 'Formatter_GetCC_ge', ID, StrL );
        InitVar( @Formatter_SetCC_ge, 'Formatter_SetCC_ge', ID, StrL );
        InitVar( @Formatter_GetCC_le, 'Formatter_GetCC_le', ID, StrL );
        InitVar( @Formatter_SetCC_le, 'Formatter_SetCC_le', ID, StrL );
        InitVar( @Formatter_GetCC_g, 'Formatter_GetCC_g', ID, StrL );
        InitVar( @Formatter_SetCC_g, 'Formatter_SetCC_g', ID, StrL );

        // Encoder
        InitVar( @Encoder_Create, 'Encoder_Create', ID, StrL );
        InitVar( @Encoder_Encode, 'Encoder_Encode', ID, StrL );
        InitVar( @Encoder_WriteByte, 'Encoder_WriteByte', ID, StrL );
        InitVar( @Encoder_GetBuffer, 'Encoder_GetBuffer', ID, StrL );
//        InitVar( @Encoder_SetBuffer, 'Encoder_SetBuffer', ID, StrL );
        InitVar( @Encoder_GetConstantOffsets, 'Encoder_GetConstantOffsets', ID, StrL );
        InitVar( @Encoder_GetPreventVex2, 'Encoder_GetPreventVex2', ID, StrL );
        InitVar( @Encoder_SetPreventVex2, 'Encoder_SetPreventVex2', ID, StrL );
        InitVar( @Encoder_GetVexWig, 'Encoder_GetVexWig', ID, StrL );
        InitVar( @Encoder_SetVexWig, 'Encoder_SetVexWig', ID, StrL );
        InitVar( @Encoder_GetVexLig, 'Encoder_GetVexLig', ID, StrL );
        InitVar( @Encoder_SetVexLig, 'Encoder_SetVexLig', ID, StrL );
        InitVar( @Encoder_GetEvexWig, 'Encoder_GetEvexWig', ID, StrL );
        InitVar( @Encoder_SetEvexWig, 'Encoder_SetEvexWig', ID, StrL );
        InitVar( @Encoder_GetEvexLig, 'Encoder_GetEvexLig', ID, StrL );
        InitVar( @Encoder_SetEvexLig, 'Encoder_SetEvexLig', ID, StrL );
        InitVar( @Encoder_GetMvexWig, 'Encoder_GetMvexWig', ID, StrL );
        InitVar( @Encoder_SetMvexWig, 'Encoder_SetMvexWig', ID, StrL );
        InitVar( @Encoder_GetBitness, 'Encoder_GetBitness', ID, StrL );

        InitVar( @BlockEncoder, 'BlockEncoder', ID, StrL );

        // Instruction
        InitVar( @Instruction_IsStackInstruction, 'Instruction_IsStackInstruction', ID, StrL );
        InitVar( @Instruction_StackPointerIncrement, 'Instruction_StackPointerIncrement', ID, StrL );
        InitVar( @Instruction_ConditionCode, 'Instruction_ConditionCode', ID, StrL );
        InitVar( @Instruction_FlowControl, 'Instruction_FlowControl', ID, StrL );
        InitVar( @Instruction_RFlagsRead, 'Instruction_RFlagsRead', ID, StrL );
        InitVar( @Instruction_RFlagsWritten, 'Instruction_RFlagsWritten', ID, StrL );
        InitVar( @Instruction_RFlagsCleared, 'Instruction_RFlagsCleared', ID, StrL );
        InitVar( @Instruction_RFlagsSet, 'Instruction_RFlagsSet', ID, StrL );
        InitVar( @Instruction_RFlagsUndefined, 'Instruction_RFlagsUndefined', ID, StrL );
        InitVar( @Instruction_RFlagsModified, 'Instruction_RFlagsModified', ID, StrL );

        InitVar( @Instruction_FPU_StackIncrementInfo, 'Instruction_FPU_StackIncrementInfo', ID, StrL );
        InitVar( @Instruction_Encoding, 'Instruction_Encoding', ID, StrL );
        InitVar( @Instruction_Mnemonic, 'Instruction_Mnemonic', ID, StrL );
        InitVar( @Instruction_CPUIDFeatures, 'Instruction_CPUIDFeatures', ID, StrL );
        InitVar( @Instruction_OPKinds, 'Instruction_OPKinds', ID, StrL );
        InitVar( @Instruction_MemorySize, 'Instruction_MemorySize', ID, StrL );
        InitVar( @Instruction_OPCount, 'Instruction_OPCount', ID, StrL );

        InitVar( @Instruction_OpCodeInfo_Code, 'Instruction_OpCodeInfo_Code', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Mnemonic, 'Instruction_OpCodeInfo_Mnemonic', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsInstruction, 'Instruction_OpCodeInfo_IsInstruction', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Mode16, 'Instruction_OpCodeInfo_Mode16', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Mode32, 'Instruction_OpCodeInfo_Mode32', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Mode64, 'Instruction_OpCodeInfo_Mode64', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Fwait, 'Instruction_OpCodeInfo_Fwait', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OperandSize, 'Instruction_OpCodeInfo_OperandSize', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AddressSize, 'Instruction_OpCodeInfo_AddressSize', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_L, 'Instruction_OpCodeInfo_L', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_W, 'Instruction_OpCodeInfo_W', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsLig, 'Instruction_OpCodeInfo_IsLig', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsWig, 'Instruction_OpCodeInfo_IsWig', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsWig32, 'Instruction_OpCodeInfo_IsWig32', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TupleType, 'Instruction_OpCodeInfo_TupleType', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexEhBit, 'Instruction_OpCodeInfo_MvexEhBit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexCanUseEvictionHint, 'Instruction_OpCodeInfo_MvexCanUseEvictionHint', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexCanUseImmRoundingControl, 'Instruction_OpCodeInfo_MvexCanUseImmRoundingControl', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexIgnoresOpMaskRegister, 'Instruction_OpCodeInfo_MvexIgnoresOpMaskRegister', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexNoSaeRc, 'Instruction_OpCodeInfo_MvexNoSaeRc', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexTupleTypeLutKind, 'Instruction_OpCodeInfo_MvexTupleTypeLutKind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexConversionFunc, 'Instruction_OpCodeInfo_MvexConversionFunc', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexValidConversionFuncsMask, 'Instruction_OpCodeInfo_MvexValidConversionFuncsMask', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MvexValidSwizzleFuncsMask, 'Instruction_OpCodeInfo_MvexValidSwizzleFuncsMask', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MemorySize, 'Instruction_OpCodeInfo_MemorySize', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_BroadcastMemorySize, 'Instruction_OpCodeInfo_BroadcastMemorySize', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanBroadcast, 'Instruction_OpCodeInfo_CanBroadcast', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseRoundingControl, 'Instruction_OpCodeInfo_CanUseRoundingControl', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanSuppressAllExceptions, 'Instruction_OpCodeInfo_CanSuppressAllExceptions', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseOpMaskRegister, 'Instruction_OpCodeInfo_CanUseOpMaskRegister', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_RequireOpMaskRegister, 'Instruction_OpCodeInfo_RequireOpMaskRegister', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseZeroingMasking, 'Instruction_OpCodeInfo_CanUseZeroingMasking', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseLockPrefix, 'Instruction_OpCodeInfo_CanUseLockPrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseXacquirePrefix, 'Instruction_OpCodeInfo_CanUseXacquirePrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseXreleasePrefix, 'Instruction_OpCodeInfo_CanUseXreleasePrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseRepPrefix, 'Instruction_OpCodeInfo_CanUseRepPrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseRepnePrefix, 'Instruction_OpCodeInfo_CanUseRepnePrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseBndPrefix, 'Instruction_OpCodeInfo_CanUseBndPrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseHintTakenPrefix, 'Instruction_OpCodeInfo_CanUseHintTakenPrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CanUseNotrackPrefix, 'Instruction_OpCodeInfo_CanUseNotrackPrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IgnoresRoundingControl, 'Instruction_OpCodeInfo_IgnoresRoundingControl', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AmdLockRegBit, 'Instruction_OpCodeInfo_AmdLockRegBit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_DefaultOpSize64, 'Instruction_OpCodeInfo_DefaultOpSize64', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_ForceOpSize64, 'Instruction_OpCodeInfo_ForceOpSize64', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelForceOpSize64, 'Instruction_OpCodeInfo_IntelForceOpSize64', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MustBeCpl0, 'Instruction_OpCodeInfo_MustBeCpl0', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Cpl0, 'Instruction_OpCodeInfo_Cpl0', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Cpl1, 'Instruction_OpCodeInfo_Cpl1', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Cpl2, 'Instruction_OpCodeInfo_Cpl2', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Cpl3, 'Instruction_OpCodeInfo_Cpl3', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsInputOutput, 'Instruction_OpCodeInfo_IsInputOutput', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsNop, 'Instruction_OpCodeInfo_IsNop', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsReservedNop, 'Instruction_OpCodeInfo_IsReservedNop', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsSerializingIntel, 'Instruction_OpCodeInfo_IsSerializingIntel', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsSerializingAmd, 'Instruction_OpCodeInfo_IsSerializingAmd', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MayRequireCpl0, 'Instruction_OpCodeInfo_MayRequireCpl0', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsCetTracked, 'Instruction_OpCodeInfo_IsCetTracked', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsNonTemporal, 'Instruction_OpCodeInfo_IsNonTemporal', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsFpuNoWait, 'Instruction_OpCodeInfo_IsFpuNoWait', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IgnoresModBits, 'Instruction_OpCodeInfo_IgnoresModBits', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_No66, 'Instruction_OpCodeInfo_No66', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Nfx, 'Instruction_OpCodeInfo_Nfx', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_RequiresUniqueRegNums, 'Instruction_OpCodeInfo_RequiresUniqueRegNums', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_RequiresUniqueDestRegNum, 'Instruction_OpCodeInfo_RequiresUniqueDestRegNum', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsPrivileged, 'Instruction_OpCodeInfo_IsPrivileged', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsSaveRestore, 'Instruction_OpCodeInfo_IsSaveRestore', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsStackInstruction, 'Instruction_OpCodeInfo_IsStackInstruction', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IgnoresSegment, 'Instruction_OpCodeInfo_IgnoresSegment', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsOpMaskReadWrite, 'Instruction_OpCodeInfo_IsOpMaskReadWrite', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_RealMode, 'Instruction_OpCodeInfo_RealMode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_ProtectedMode, 'Instruction_OpCodeInfo_ProtectedMode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Virtual8086Mode, 'Instruction_OpCodeInfo_Virtual8086Mode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_CompatibilityMode, 'Instruction_OpCodeInfo_CompatibilityMode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_LongMode, 'Instruction_OpCodeInfo_LongMode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseOutsideSmm, 'Instruction_OpCodeInfo_UseOutsideSmm', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseInSmm, 'Instruction_OpCodeInfo_UseInSmm', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseOutsideEnclaveSgx, 'Instruction_OpCodeInfo_UseOutsideEnclaveSgx', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseInEnclaveSgx1, 'Instruction_OpCodeInfo_UseInEnclaveSgx1', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseInEnclaveSgx2, 'Instruction_OpCodeInfo_UseInEnclaveSgx2', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseOutsideVmxOp, 'Instruction_OpCodeInfo_UseOutsideVmxOp', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseInVmxRootOp, 'Instruction_OpCodeInfo_UseInVmxRootOp', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseInVmxNonRootOp, 'Instruction_OpCodeInfo_UseInVmxNonRootOp', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseOutsideSeam, 'Instruction_OpCodeInfo_UseOutsideSeam', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_UseInSeam, 'Instruction_OpCodeInfo_UseInSeam', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TdxNonRootGenUd, 'Instruction_OpCodeInfo_TdxNonRootGenUd', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TdxNonRootGenVe, 'Instruction_OpCodeInfo_TdxNonRootGenVe', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TdxNonRootMayGenEx, 'Instruction_OpCodeInfo_TdxNonRootMayGenEx', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelVMExit, 'Instruction_OpCodeInfo_IntelVMExit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelMayVMExit, 'Instruction_OpCodeInfo_IntelMayVMExit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelSmmVMExit, 'Instruction_OpCodeInfo_IntelSmmVMExit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AmdVMExit, 'Instruction_OpCodeInfo_AmdVMExit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AmdMayVMExit, 'Instruction_OpCodeInfo_AmdMayVMExit', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TsxAbort, 'Instruction_OpCodeInfo_TsxAbort', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TsxImplAbort, 'Instruction_OpCodeInfo_TsxImplAbort', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_TsxMayAbort, 'Instruction_OpCodeInfo_TsxMayAbort', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelDecoder16, 'Instruction_OpCodeInfo_IntelDecoder16', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelDecoder32, 'Instruction_OpCodeInfo_IntelDecoder32', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IntelDecoder64, 'Instruction_OpCodeInfo_IntelDecoder64', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AmdDecoder16, 'Instruction_OpCodeInfo_AmdDecoder16', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AmdDecoder32, 'Instruction_OpCodeInfo_AmdDecoder32', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_AmdDecoder64, 'Instruction_OpCodeInfo_AmdDecoder64', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_DecoderOption, 'Instruction_OpCodeInfo_DecoderOption', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_Table, 'Instruction_OpCodeInfo_Table', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_MandatoryPrefix, 'Instruction_OpCodeInfo_MandatoryPrefix', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OpCode, 'Instruction_OpCodeInfo_OpCode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OpCodeLen, 'Instruction_OpCodeInfo_OpCodeLen', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsGroup, 'Instruction_OpCodeInfo_IsGroup', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_GroupIndex, 'Instruction_OpCodeInfo_GroupIndex', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsRMGroup, 'Instruction_OpCodeInfo_IsRMGroup', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_RMGroupIndex, 'Instruction_OpCodeInfo_RMGroupIndex', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OPCount, 'Instruction_OpCodeInfo_OPCount', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OP0Kind, 'Instruction_OpCodeInfo_OP0Kind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OP1Kind, 'Instruction_OpCodeInfo_OP1Kind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OP2Kind, 'Instruction_OpCodeInfo_OP2Kind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OP3Kind, 'Instruction_OpCodeInfo_OP3Kind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OP4Kind, 'Instruction_OpCodeInfo_OP4Kind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OPKind, 'Instruction_OpCodeInfo_OPKind', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OPKinds, 'Instruction_OpCodeInfo_OPKinds', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_IsAvailableInMode, 'Instruction_OpCodeInfo_IsAvailableInMode', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_OpCodeString, 'Instruction_OpCodeInfo_OpCodeString', ID, StrL );
        InitVar( @Instruction_OpCodeInfo_InstructionString, 'Instruction_OpCodeInfo_InstructionString', ID, StrL );
        InitVar( @Instruction_VirtualAddress, 'Instruction_VirtualAddress', ID, StrL );

        InitVar( @InstructionInfoFactory_Create, 'InstructionInfoFactory_Create', ID, StrL );
        InitVar( @InstructionInfoFactory_Info, 'InstructionInfoFactory_Info', ID, StrL );

        // Instruction
        InitVar( @Instruction_With, 'Instruction_With', ID, StrL );
        InitVar( @Instruction_With1_Register, 'Instruction_With1_Register', ID, StrL );
        InitVar( @Instruction_With1_i32, 'Instruction_With1_i32', ID, StrL );
        InitVar( @Instruction_With1_u32, 'Instruction_With1_u32', ID, StrL );
        InitVar( @Instruction_With1_Memory, 'Instruction_With1_Memory', ID, StrL );
        InitVar( @Instruction_With2_Register_Register, 'Instruction_With2_Register_Register', ID, StrL );
        InitVar( @Instruction_With2_Register_i32, 'Instruction_With2_Register_i32', ID, StrL );
        InitVar( @Instruction_With2_Register_u32, 'Instruction_With2_Register_u32', ID, StrL );
        InitVar( @Instruction_With2_Register_i64, 'Instruction_With2_Register_i64', ID, StrL );
        InitVar( @Instruction_With2_Register_u64, 'Instruction_With2_Register_u64', ID, StrL );
        InitVar( @Instruction_With2_Register_MemoryOperand, 'Instruction_With2_Register_MemoryOperand', ID, StrL );
        InitVar( @Instruction_With2_i32_Register, 'Instruction_With2_i32_Register', ID, StrL );
        InitVar( @Instruction_With2_u32_Register, 'Instruction_With2_u32_Register', ID, StrL );
        InitVar( @Instruction_With2_i32_i32, 'Instruction_With2_i32_i32', ID, StrL );
        InitVar( @Instruction_With2_u32_u32, 'Instruction_With2_u32_u32', ID, StrL );
        InitVar( @Instruction_With2_MemoryOperand_Register, 'Instruction_With2_MemoryOperand_Register', ID, StrL );
        InitVar( @Instruction_With2_MemoryOperand_i32, 'Instruction_With2_MemoryOperand_i32', ID, StrL );
        InitVar( @Instruction_With2_MemoryOperand_u32, 'Instruction_With2_MemoryOperand_u32', ID, StrL );
        InitVar( @Instruction_With3_Register_Register_Register, 'Instruction_With3_Register_Register_Register', ID, StrL );
        InitVar( @Instruction_With3_Register_Register_i32, 'Instruction_With3_Register_Register_i32', ID, StrL );
        InitVar( @Instruction_With3_Register_Register_u32, 'Instruction_With3_Register_Register_u32', ID, StrL );
        InitVar( @Instruction_With3_Register_Register_MemoryOperand, 'Instruction_With3_Register_Register_MemoryOperand', ID, StrL );
        InitVar( @Instruction_With3_Register_i32_i32, 'Instruction_With3_Register_i32_i32', ID, StrL );
        InitVar( @Instruction_With3_Register_u32_u32, 'Instruction_With3_Register_u32_u32', ID, StrL );
        InitVar( @Instruction_With3_Register_MemoryOperand_Register, 'Instruction_With3_Register_MemoryOperand_Register', ID, StrL );
        InitVar( @Instruction_With3_Register_MemoryOperand_i32, 'Instruction_With3_Register_MemoryOperand_i32', ID, StrL );
        InitVar( @Instruction_With3_Register_MemoryOperand_u32, 'Instruction_With3_Register_MemoryOperand_u32', ID, StrL );
        InitVar( @Instruction_With3_MemoryOperand_Register_Register, 'Instruction_With3_MemoryOperand_Register_Register', ID, StrL );
        InitVar( @Instruction_With3_MemoryOperand_Register_i32, 'Instruction_With3_MemoryOperand_Register_i32', ID, StrL );
        InitVar( @Instruction_With3_MemoryOperand_Register_u32, 'Instruction_With3_MemoryOperand_Register_u32', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_Register_Register, 'Instruction_With4_Register_Register_Register_Register', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_Register_i32, 'Instruction_With4_Register_Register_Register_i32', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_Register_u32, 'Instruction_With4_Register_Register_Register_u32', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_Register_MemoryOperand, 'Instruction_With4_Register_Register_Register_MemoryOperand', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_i32_i32, 'Instruction_With4_Register_Register_i32_i32', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_u32_u32, 'Instruction_With4_Register_Register_u32_u32', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_MemoryOperand_Register, 'Instruction_With4_Register_Register_MemoryOperand_Register', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_MemoryOperand_i32, 'Instruction_With4_Register_Register_MemoryOperand_i32', ID, StrL );
        InitVar( @Instruction_With4_Register_Register_MemoryOperand_u32, 'Instruction_With4_Register_Register_MemoryOperand_u32', ID, StrL );
        InitVar( @Instruction_With5_Register_Register_Register_Register_i32, 'Instruction_With5_Register_Register_Register_Register_i32', ID, StrL );
        InitVar( @Instruction_With5_Register_Register_Register_Register_u32, 'Instruction_With5_Register_Register_Register_Register_u32', ID, StrL );
        InitVar( @Instruction_With5_Register_Register_Register_MemoryOperand_i32, 'Instruction_With5_Register_Register_Register_MemoryOperand_i32', ID, StrL );
        InitVar( @Instruction_With5_Register_Register_Register_MemoryOperand_u32, 'Instruction_With5_Register_Register_Register_MemoryOperand_u32', ID, StrL );
        InitVar( @Instruction_With5_Register_Register_MemoryOperand_Register_i32, 'Instruction_With5_Register_Register_MemoryOperand_Register_i32', ID, StrL );
        InitVar( @Instruction_With5_Register_Register_MemoryOperand_Register_u32, 'Instruction_With5_Register_Register_MemoryOperand_Register_u32', ID, StrL );
        InitVar( @Instruction_With_Branch, 'Instruction_With_Branch', ID, StrL );
        InitVar( @Instruction_With_Far_Branch, 'Instruction_With_Far_Branch', ID, StrL );
        InitVar( @Instruction_With_xbegin, 'Instruction_With_xbegin', ID, StrL );
        InitVar( @Instruction_With_outsb, 'Instruction_With_outsb', ID, StrL );
        InitVar( @Instruction_With_Rep_outsb, 'Instruction_With_Rep_outsb', ID, StrL );
        InitVar( @Instruction_With_outsw, 'Instruction_With_outsw', ID, StrL );
        InitVar( @Instruction_With_Rep_outsw, 'Instruction_With_Rep_outsw', ID, StrL );
        InitVar( @Instruction_With_outsd, 'Instruction_With_outsd', ID, StrL );
        InitVar( @Instruction_With_Rep_outsd, 'Instruction_With_Rep_outsd', ID, StrL );
        InitVar( @Instruction_With_lodsb, 'Instruction_With_lodsb', ID, StrL );
        InitVar( @Instruction_With_Rep_lodsb, 'Instruction_With_Rep_lodsb', ID, StrL );
        InitVar( @Instruction_With_lodsw, 'Instruction_With_lodsw', ID, StrL );
        InitVar( @Instruction_With_Rep_lodsw, 'Instruction_With_Rep_lodsw', ID, StrL );
        InitVar( @Instruction_With_lodsd, 'Instruction_With_lodsd', ID, StrL );
        InitVar( @Instruction_With_Rep_lodsd, 'Instruction_With_Rep_lodsd', ID, StrL );
        InitVar( @Instruction_With_lodsq, 'Instruction_With_lodsq', ID, StrL );
        InitVar( @Instruction_With_Rep_lodsq, 'Instruction_With_Rep_lodsq', ID, StrL );
        InitVar( @Instruction_With_scasb, 'Instruction_With_scasb', ID, StrL );
        InitVar( @Instruction_With_Repe_scasb, 'Instruction_With_Repe_scasb', ID, StrL );
        InitVar( @Instruction_With_Repne_scasb, 'Instruction_With_Repne_scasb', ID, StrL );
        InitVar( @Instruction_With_scasw, 'Instruction_With_scasw', ID, StrL );
        InitVar( @Instruction_With_Repe_scasw, 'Instruction_With_Repe_scasw', ID, StrL );
        InitVar( @Instruction_With_Repne_scasw, 'Instruction_With_Repne_scasw', ID, StrL );
        InitVar( @Instruction_With_scasd, 'Instruction_With_scasd', ID, StrL );
        InitVar( @Instruction_With_Repe_scasd, 'Instruction_With_Repe_scasd', ID, StrL );
        InitVar( @Instruction_With_Repne_scasd, 'Instruction_With_Repne_scasd', ID, StrL );
        InitVar( @Instruction_With_scasq, 'Instruction_With_scasq', ID, StrL );
        InitVar( @Instruction_With_Repe_scasq, 'Instruction_With_Repe_scasq', ID, StrL );
        InitVar( @Instruction_With_Repne_scasq, 'Instruction_With_Repne_scasq', ID, StrL );
        InitVar( @Instruction_With_insb, 'Instruction_With_insb', ID, StrL );
        InitVar( @Instruction_With_Rep_insb, 'Instruction_With_Rep_insb', ID, StrL );
        InitVar( @Instruction_With_insw, 'Instruction_With_insw', ID, StrL );
        InitVar( @Instruction_With_Rep_insw, 'Instruction_With_Rep_insw', ID, StrL );
        InitVar( @Instruction_With_insd, 'Instruction_With_insd', ID, StrL );
        InitVar( @Instruction_With_Rep_insd, 'Instruction_With_Rep_insd', ID, StrL );
        InitVar( @Instruction_With_stosb, 'Instruction_With_stosb', ID, StrL );
        InitVar( @Instruction_With_Rep_stosb, 'Instruction_With_Rep_stosb', ID, StrL );
        InitVar( @Instruction_With_stosw, 'Instruction_With_stosw', ID, StrL );
        InitVar( @Instruction_With_Rep_stosw, 'Instruction_With_Rep_stosw', ID, StrL );
        InitVar( @Instruction_With_stosd, 'Instruction_With_stosd', ID, StrL );
        InitVar( @Instruction_With_Rep_stosd, 'Instruction_With_Rep_stosd', ID, StrL );
        InitVar( @Instruction_With_Rep_stosq, 'Instruction_With_Rep_stosq', ID, StrL );
        InitVar( @Instruction_With_cmpsb, 'Instruction_With_cmpsb', ID, StrL );
        InitVar( @Instruction_With_Repe_cmpsb, 'Instruction_With_Repe_cmpsb', ID, StrL );
        InitVar( @Instruction_With_Repne_cmpsb, 'Instruction_With_Repne_cmpsb', ID, StrL );
        InitVar( @Instruction_With_cmpsw, 'Instruction_With_cmpsw', ID, StrL );
        InitVar( @Instruction_With_Repe_cmpsw, 'Instruction_With_Repe_cmpsw', ID, StrL );
        InitVar( @Instruction_With_Repne_cmpsw, 'Instruction_With_Repne_cmpsw', ID, StrL );
        InitVar( @Instruction_With_cmpsd, 'Instruction_With_cmpsd', ID, StrL );
        InitVar( @Instruction_With_Repe_cmpsd, 'Instruction_With_Repe_cmpsd', ID, StrL );
        InitVar( @Instruction_With_Repne_cmpsd, 'Instruction_With_Repne_cmpsd', ID, StrL );
        InitVar( @Instruction_With_cmpsq, 'Instruction_With_cmpsq', ID, StrL );
        InitVar( @Instruction_With_Repe_cmpsq, 'Instruction_With_Repe_cmpsq', ID, StrL );
        InitVar( @Instruction_With_Repne_cmpsq, 'Instruction_With_Repne_cmpsq', ID, StrL );
        InitVar( @Instruction_With_movsb, 'Instruction_With_movsb', ID, StrL );
        InitVar( @Instruction_With_Rep_movsb, 'Instruction_With_Rep_movsb', ID, StrL );
        InitVar( @Instruction_With_movsw, 'Instruction_With_movsw', ID, StrL );
        InitVar( @Instruction_With_Rep_movsw, 'Instruction_With_Rep_movsw', ID, StrL );
        InitVar( @Instruction_With_movsd, 'Instruction_With_movsd', ID, StrL );
        InitVar( @Instruction_With_Rep_movsd, 'Instruction_With_Rep_movsd', ID, StrL );
        InitVar( @Instruction_With_movsq, 'Instruction_With_movsq', ID, StrL );
        InitVar( @Instruction_With_Rep_movsq, 'Instruction_With_Rep_movsq', ID, StrL );
        InitVar( @Instruction_With_maskmovq, 'Instruction_With_maskmovq', ID, StrL );
        InitVar( @Instruction_With_maskmovdqu, 'Instruction_With_maskmovdqu', ID, StrL );
        InitVar( @Instruction_With_vmaskmovdqu, 'Instruction_With_vmaskmovdqu', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_1, 'Instruction_With_Declare_Byte_1', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_2, 'Instruction_With_Declare_Byte_2', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_3, 'Instruction_With_Declare_Byte_3', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_4, 'Instruction_With_Declare_Byte_4', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_5, 'Instruction_With_Declare_Byte_5', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_6, 'Instruction_With_Declare_Byte_6', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_7, 'Instruction_With_Declare_Byte_7', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_8, 'Instruction_With_Declare_Byte_8', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_9, 'Instruction_With_Declare_Byte_9', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_10, 'Instruction_With_Declare_Byte_10', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_11, 'Instruction_With_Declare_Byte_11', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_12, 'Instruction_With_Declare_Byte_12', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_13, 'Instruction_With_Declare_Byte_13', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_14, 'Instruction_With_Declare_Byte_14', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_15, 'Instruction_With_Declare_Byte_15', ID, StrL );
        InitVar( @Instruction_With_Declare_Byte_16, 'Instruction_With_Declare_Byte_16', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_1, 'Instruction_With_Declare_Word_1', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_2, 'Instruction_With_Declare_Word_2', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_3, 'Instruction_With_Declare_Word_3', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_4, 'Instruction_With_Declare_Word_4', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_5, 'Instruction_With_Declare_Word_5', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_6, 'Instruction_With_Declare_Word_6', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_7, 'Instruction_With_Declare_Word_7', ID, StrL );
        InitVar( @Instruction_With_Declare_Word_8, 'Instruction_With_Declare_Word_8', ID, StrL );
        InitVar( @Instruction_With_Declare_DWord_1, 'Instruction_With_Declare_DWord_1', ID, StrL );
        InitVar( @Instruction_With_Declare_DWord_2, 'Instruction_With_Declare_DWord_2', ID, StrL );
        InitVar( @Instruction_With_Declare_DWord_3, 'Instruction_With_Declare_DWord_3', ID, StrL );
        InitVar( @Instruction_With_Declare_DWord_4, 'Instruction_With_Declare_DWord_4', ID, StrL );
        InitVar( @Instruction_With_Declare_QWord_1, 'Instruction_With_Declare_QWord_1', ID, StrL );
        InitVar( @Instruction_With_Declare_QWord_2, 'Instruction_With_Declare_QWord_2', ID, StrL );
        end;
  end;

  {$WARNINGS ON}
  {$UNDEF section_InitVar}
end;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Redirects~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$DEFINE section_Redirects}
{.$I Iced.inc}
{$UNDEF section_Redirects}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$DEFINE section_IMPLEMENTATION}
{$I DynamicDLL.inc}
{$UNDEF section_IMPLEMENTATION}

end.
