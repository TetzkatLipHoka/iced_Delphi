unit uIced.Imports;

{
  Iced (Dis)Assembler

  TetzkatLipHoka 2022-2023
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
  DLLVersion_ : Array [0..DLLCount_-1] of String = ( '1.0.3.0' );
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
  IcedFreeMemory : function( Pointer : Pointer ) : Boolean; cdecl;

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
  Decoder_Create : function( Bitness : Cardinal; Data : PByte; DataSize : NativeUInt; IP : UInt64; Options : Cardinal = doNONE ) : Pointer; cdecl;

  // Returns `true` if there's at least one more byte to decode. It doesn't verify that the
  // next instruction is valid, it only checks if there's at least one more byte to read.
  // See also [`position()`] and [`max_position()`]
  //
  // It's not required to call this method. If this method returns `false`, then [`decode_out()`]
  // and [`decode()`] will return an instruction whose [`code()`] == [`Code::INVALID`].
  Decoder_CanDecode : function( Decoder : Pointer ) : Boolean; cdecl;

  // Gets the current `IP`/`EIP`/`RIP` value, see also [`position()`]
  Decoder_GetIP : function( Decoder : Pointer ) : UInt64; cdecl;

  // Sets the current `IP`/`EIP`/`RIP` value, see also [`try_set_position()`]
  // This method only updates the IP value, it does not change the data position, use [`try_set_position()`] to change the position.
  Decoder_SetIP : function ( Decoder : Pointer; Value : UInt64 ) : boolean; cdecl;

  // Gets the bitness (16, 32 or 64)
  Decoder_GetBitness : function( Decoder : Pointer ) : Cardinal; cdecl;

  // Gets the max value that can be passed to [`try_set_position()`]. This is the size of the data that gets
  // decoded to instructions and it's the length of the slice that was passed to the constructor.
  Decoder_GetMaxPosition : function( Decoder : Pointer ) : NativeUInt; cdecl;

  // Gets the current data position. This value is always <= [`max_position()`].
  // When [`position()`] == [`max_position()`], it's not possible to decode more
  // instructions and [`can_decode()`] returns `false`.
  Decoder_GetPosition : function( Decoder : Pointer ) : NativeUInt; cdecl;

  // Sets the current data position, which is the index into the data passed to the constructor.
  // This value is always <= [`max_position()`]
  Decoder_SetPosition : function ( Decoder : Pointer; Value : NativeUInt ) : boolean; cdecl;

  // Gets the last decoder error. Unless you need to know the reason it failed,
  // it's better to check [`instruction.is_invalid()`].
  Decoder_GetLastError : function( Decoder : Pointer ) : TDecoderError; cdecl;

  // Decodes and returns the next instruction, see also [`decode_out(&mut Instruction)`]
  // which avoids copying the decoded instruction to the caller's return variable.
  // See also [`last_error()`].
  Decoder_Decode : procedure( Decoder : Pointer; var Instruction : TInstruction ); cdecl;

  // Gets the offsets of the constants (memory displacement and immediate) in the decoded instruction.
  // The caller can check if there are any relocations at those addresses.
  //
  // # Arguments
  // * `instruction`: The latest instruction that was decoded by this decoder
  Decoder_GetConstantOffsets : function( Decoder : Pointer; var Instruction : TInstruction; var ConstantOffsets : TConstantOffsets ) : Boolean; cdecl;

  // Creates a formatter Output Callback
  FormatterOutput_Create : function( Callback : TFormatterOutputCallback; UserData : Pointer = nil ) : Pointer; cdecl;

  // Creates a masm formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  MasmFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl;

  // Format Instruction
  MasmFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ); cdecl;
  MasmFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl;

  // Creates a Nasm formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  NasmFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl;

  // Format Instruction
  NasmFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ); cdecl;
  NasmFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl;

  // Creates a Gas formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  GasFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl;

  // Format Instruction
  GasFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl;
  GasFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl;

  // Creates a Intel formatter
  //
  // # Arguments
  // - `symbol_resolver`: Symbol resolver or `None`
  // - `options_provider`: Operand options provider or `None`
  IntelFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; OptionsProvider : TFormatterOptionsProviderCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl;

  // Format Instruction
  IntelFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl;
  IntelFormatter_FormatCallback : procedure( Formatter : Pointer; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl;

  // Creates a Fast formatter (Specialized)
  // NOTE: Fast Formatter only supports Specialized-Options
  FastFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; UserData : Pointer = nil ) : Pointer; cdecl;

  // Format Instruction
  FastFormatter_Format : procedure( Formatter : Pointer; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl;

  // Creates a Specialized formatter
  SpecializedFormatter_Create : function( SymbolResolver : TSymbolResolverCallback = nil; DBDWDDDQ : Boolean = False; UserData : Pointer = nil ) : Pointer; cdecl;

  // Format Instruction
  SpecializedFormatter_Format : procedure( Formatter : Pointer; FormatterType : TIcedSpecializedFormatterType; var Instruction: TInstruction; output: PAnsiChar; Size : NativeUInt ); cdecl;

// Options
  // NOTE: Specialized Formatter only supports the following Options

  // Always show the size of memory operands
  //
  // Default | Value | Example | Example
  // --------|-------|---------|--------
  // _ | `true` | `mov eax,dword ptr [ebx]` | `add byte ptr [eax],0x12`
  // X | `false` | `mov eax,[ebx]` | `add byte ptr [eax],0x12`
  SpecializedFormatter_GetAlwaysShowMemorySize : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType ) : boolean; cdecl;

  // Always show the size of memory operands
  //
  // Default | Value | Example | Example
  // --------|-------|---------|--------
  // _ | `true` | `mov eax,dword ptr [ebx]` | `add byte ptr [eax],0x12`
  // X | `false` | `mov eax,[ebx]` | `add byte ptr [eax],0x12`
  //
  // # Arguments
  // * `value`: New value
  SpecializedFormatter_SetAlwaysShowMemorySize : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType; Value : Boolean ) : boolean; cdecl;

  // Use a hex prefix ( `0x` ) or a hex suffix ( `h` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x5A`
  // X | `false` | `5Ah`
  SpecializedFormatter_GetUseHexPrefix : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType ) : boolean; cdecl;

  // Use a hex prefix ( `0x` ) or a hex suffix ( `h` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x5A`
  // X | `false` | `5Ah`
  //
  // # Arguments
  // * `value`: New value
  SpecializedFormatter_SetUseHexPrefix : function( Formatter: Pointer; FormatterType : TIcedSpecializedFormatterType; Value : Boolean ) : boolean; cdecl;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Formatter Options
  // Format Instruction
  Formatter_Format : procedure( Formatter : Pointer; FormatterType : TIcedFormatterType; var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ); cdecl;
  Formatter_FormatCallback : procedure( Formatter : Pointer; FormatterType : TIcedFormatterType; var Instruction: TInstruction; FormatterOutput: Pointer ); cdecl;

  // Prefixes are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `REP stosd`
  // X | `false` | `rep stosd`
  Formatter_GetUpperCasePrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

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
  Formatter_SetUpperCasePrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Mnemonics are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV rcx,rax`
  // X | `false` | `mov rcx,rax`
  Formatter_GetUpperCaseMnemonics : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Mnemonics are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV rcx,rax`
  // X | `false` | `mov rcx,rax`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseMnemonics : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Registers are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov RCX,[RAX+RDX*8]`
  // X | `false` | `mov rcx,[rax+rdx*8]`
  Formatter_GetUpperCaseRegisters : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Registers are uppercased
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov RCX,[RAX+RDX*8]`
  // X | `false` | `mov rcx,[rax+rdx*8]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseRegisters : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Keywords are uppercased ( eg. `BYTE PTR`, `SHORT` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov BYTE PTR [rcx],12h`
  // X | `false` | `mov byte ptr [rcx],12h`
  Formatter_GetUpperCaseKeyWords : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Keywords are uppercased ( eg. `BYTE PTR`, `SHORT` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov BYTE PTR [rcx],12h`
  // X | `false` | `mov byte ptr [rcx],12h`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseKeyWords : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Uppercase decorators, eg. `{z  ); `, `{sae  ); `, `{rd-sae  ); ` ( but not opmask registers: `{k1  ); ` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `vunpcklps xmm2{k5  ); {Z  ); ,xmm6,dword bcst [rax+4]`
  // X | `false` | `vunpcklps xmm2{k5  ); {z  ); ,xmm6,dword bcst [rax+4]`
  Formatter_GetUpperCaseDecorators : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Uppercase decorators, eg. `{z  ); `, `{sae  ); `, `{rd-sae  ); ` ( but not opmask registers: `{k1  ); ` )
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `vunpcklps xmm2{k5  ); {Z  ); ,xmm6,dword bcst [rax+4]`
  // X | `false` | `vunpcklps xmm2{k5  ); {z  ); ,xmm6,dword bcst [rax+4]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUpperCaseDecorators : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Everything is uppercased, except numbers and their prefixes/suffixes
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `MOV EAX,GS:[RCX*4+0ffh]`
  // X | `false` | `mov eax,gs:[rcx*4+0ffh]`
  Formatter_GetUpperCaseEverything : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

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
  Formatter_SetUpperCaseEverything : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Character index ( 0-based ) where the first operand is formatted. Can be set to 0 to format it immediately after the mnemonic.
  // At least one space or tab is always added between the mnemonic and the first operand.
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `0` | `mov•rcx,rbp`
  // _ | `8` | `mov•••••rcx,rbp`
  Formatter_GetFirstOperandCharIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl;

  // Character index ( 0-based ) where the first operand is formatted. Can be set to 0 to format it immediately after the mnemonic.
  // At least one space or tab is always added between the mnemonic and the first operand.
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `0` | `mov•rcx,rbp`
  // _ | `8` | `mov•••••rcx,rbp`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetFirstOperandCharIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl;

  // Size of a tab character or 0 to use spaces
  //
  // - Default: `0`
  Formatter_GetTabSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl;

  // Size of a tab character or 0 to use spaces
  //
  // - Default: `0`
  //
  // # Arguments
  //
  // * `value`: New value
  Formatter_SetTabSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl;

  // Add a space after the operand separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov rax, rcx`
  // X | `false` | `mov rax,rcx`
  Formatter_GetSpaceAfterOperandSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add a space after the operand separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov rax, rcx`
  // X | `false` | `mov rax,rcx`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceAfterOperandSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Add a space between the memory expression and the brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[ rcx+rdx ]`
  // X | `false` | `mov eax,[rcx+rdx]`
  Formatter_GetSpaceAfterMemoryBracket : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add a space between the memory expression and the brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[ rcx+rdx ]`
  // X | `false` | `mov eax,[rcx+rdx]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceAfterMemoryBracket : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Add spaces between memory operand `+` and `-` operators
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx + rdx*8 - 80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  Formatter_GetSpaceBetweenMemoryAddOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add spaces between memory operand `+` and `-` operators
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx + rdx*8 - 80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceBetweenMemoryAddOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Add spaces between memory operand `*` operator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx+rdx * 8-80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  Formatter_GetSpaceBetweenMemoryMulOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add spaces between memory operand `*` operator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx+rdx * 8-80h]`
  // X | `false` | `mov eax,[rcx+rdx*8-80h]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSpaceBetweenMemoryMulOperators : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Show memory operand scale value before the index register
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[8*rdx]`
  // X | `false` | `mov eax,[rdx*8]`
  Formatter_GetScaleBeforeIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Show memory operand scale value before the index register
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[8*rdx]`
  // X | `false` | `mov eax,[rdx*8]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetScaleBeforeIndex : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Always show the scale value even if it's `*1`
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rbx+rcx*1]`
  // X | `false` | `mov eax,[rbx+rcx]`
  Formatter_GetAlwaysShowScale : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Always show the scale value even if it's `*1`
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rbx+rcx*1]`
  // X | `false` | `mov eax,[rbx+rcx]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetAlwaysShowScale : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Always show the effective segment register. If the option is `false`, only show the segment register if
  // there's a segment override prefix.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ds:[ecx]`
  // X | `false` | `mov eax,[ecx]`
  Formatter_GetAlwaysShowSegmentRegister : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

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
  Formatter_SetAlwaysShowSegmentRegister : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Show zero displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx*2+0]`
  // X | `false` | `mov eax,[rcx*2]`
  Formatter_GetShowZeroDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Show zero displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rcx*2+0]`
  // X | `false` | `mov eax,[rcx*2]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetShowZeroDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Hex number prefix or an empty string, eg. `"0x"`
  //
  // - Default: `""` ( masm/nasm/intel ), `"0x"` ( gas )
  Formatter_GetHexPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Hex number prefix or an empty string, eg. `"0x"`
  //
  // - Default: `""` ( masm/nasm/intel ), `"0x"` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetHexPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Hex number suffix or an empty string, eg. `"h"`
  //
  // - Default: `"h"` ( masm/nasm/intel ), `""` ( gas )
  Formatter_GetHexSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Hex number suffix or an empty string, eg. `"h"`
  //
  // - Default: `"h"` ( masm/nasm/intel ), `""` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetHexSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `0x12345678`
  // X | `4` | `0x1234_5678`
  Formatter_GetHexDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl;

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
  Formatter_SetHexDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl;

  // Decimal number prefix or an empty string
  //
  // - Default: `""`
  Formatter_GetDecimalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Decimal number prefix or an empty string
  //
  // - Default: `""`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDecimalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Decimal number suffix or an empty string
  //
  // - Default: `""`
  Formatter_GetDecimalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Decimal number suffix or an empty string
  //
  // - Default: `""`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDecimalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `12345678`
  // X | `3` | `12_345_678`
  Formatter_GetDecimalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl;

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
  Formatter_SetDecimalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl;

  // Octal number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0"` ( gas )
  Formatter_GetOctalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Octal number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0"` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetOctalPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Octal number suffix or an empty string
  //
  // - Default: `"o"` ( masm/nasm/intel ), `""` ( gas )
  Formatter_GetOctalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Octal number suffix or an empty string
  //
  // - Default: `"o"` ( masm/nasm/intel ), `""` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetOctalSuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `12345670`
  // X | `4` | `1234_5670`
  Formatter_GetOctalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl;

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
  Formatter_SetOctalDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl;

  // Binary number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0b"` ( gas )
  Formatter_GetBinaryPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Binary number prefix or an empty string
  //
  // - Default: `""` ( masm/nasm/intel ), `"0b"` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBinaryPrefix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Binary number suffix or an empty string
  //
  // - Default: `"b"` ( masm/nasm/intel ), `""` ( gas )
  Formatter_GetBinarySuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

  // Binary number suffix or an empty string
  //
  // - Default: `"b"` ( masm/nasm/intel ), `""` ( gas )
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBinarySuffix : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Size of a digit group, see also [`digit_separator(  )`]
  //
  // [`digit_separator(  )`]: #method.digit_separator
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `0` | `11010111`
  // X | `4` | `1101_0111`
  Formatter_GetBinaryDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : Cardinal; cdecl;

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
  Formatter_SetBinaryDigitGroupSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Cardinal ) : boolean; cdecl;

  // Digit separator or an empty string. See also eg. [`hex_digit_group_size(  )`]
  //
  // [`hex_digit_group_size(  )`]: #method.hex_digit_group_size
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `""` | `0x12345678`
  // _ | `"_"` | `0x1234_5678`
  Formatter_GetDigitSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar; Size : NativeUInt ) : NativeUInt; cdecl;

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
  Formatter_SetDigitSeparator : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : PAnsiChar ) : boolean; cdecl;

  // Add leading zeros to hexadecimal/octal/binary numbers.
  // This option has no effect on branch targets and displacements, use [`branch_leading_zeros`]
  // and [`displacement_leading_zeros`].
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `0x0000000A`/`0000000Ah`
  // X | `false` | `0xA`/`0Ah`
  Formatter_GetLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

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
  Formatter_SetLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Use uppercase hex digits
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0xFF`
  // _ | `false` | `0xff`
  Formatter_GetUppercaseHex : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Use uppercase hex digits
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0xFF`
  // _ | `false` | `0xff`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUppercaseHex : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Small hex numbers ( -9 .. 9 ) are shown in decimal
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `9`
  // _ | `false` | `0x9`
  Formatter_GetSmallHexNumbersInDecimal : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Small hex numbers ( -9 .. 9 ) are shown in decimal
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `9`
  // _ | `false` | `0x9`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSmallHexNumbersInDecimal : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Add a leading zero to hex numbers if there's no prefix and the number starts with hex digits `A-F`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0FFh`
  // _ | `false` | `FFh`
  Formatter_GetAddLeadingZeroToHexNumbers : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add a leading zero to hex numbers if there's no prefix and the number starts with hex digits `A-F`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `0FFh`
  // _ | `false` | `FFh`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetAddLeadingZeroToHexNumbers : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Number base
  //
  // - Default: [`Hexadecimal`]
  //
  // [`Hexadecimal`]: enum.NumberBase.html#variant.Hexadecimal
  Formatter_GetNumberBase : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TNumberBase; cdecl;

  // Number base
  //
  // - Default: [`Hexadecimal`]
  //
  // [`Hexadecimal`]: enum.NumberBase.html#variant.Hexadecimal
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetNumberBase : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TNumberBase ) : boolean; cdecl;

  // Add leading zeros to branch offsets. Used by `CALL NEAR`, `CALL FAR`, `JMP NEAR`, `JMP FAR`, `Jcc`, `LOOP`, `LOOPcc`, `XBEGIN`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je 00000123h`
  // _ | `false` | `je 123h`
  Formatter_GetBranchLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add leading zeros to branch offsets. Used by `CALL NEAR`, `CALL FAR`, `JMP NEAR`, `JMP FAR`, `Jcc`, `LOOP`, `LOOPcc`, `XBEGIN`
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je 00000123h`
  // _ | `false` | `je 123h`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetBranchLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Show immediate operands as signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,-1`
  // X | `false` | `mov eax,FFFFFFFF`
  Formatter_GetSignedImmediateOperands : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Show immediate operands as signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,-1`
  // X | `false` | `mov eax,FFFFFFFF`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetSignedImmediateOperands : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Displacements are signed numbers
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov al,[eax-2000h]`
  // _ | `false` | `mov al,[eax+0FFFFE000h]`
  Formatter_GetSignedMemoryDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

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
  Formatter_SetSignedMemoryDisplacements : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Add leading zeros to displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov al,[eax+00000012h]`
  // X | `false` | `mov al,[eax+12h]`
  Formatter_GetDisplacementLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Add leading zeros to displacements
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov al,[eax+00000012h]`
  // X | `false` | `mov al,[eax+12h]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetDisplacementLeadingZeros : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Options that control if the memory size ( eg. `DWORD PTR` ) is shown or not.
  // This is ignored by the gas ( AT&T ) formatter.
  //
  // - Default: [`Default`]
  //
  // [`Default`]: enum.MemorySizeOptions.html#variant.Default
type
  TMemorySizeOptions = (
    // Show memory size if the assembler requires it, else don't show anything
    msoDefault = 0,
    // Always show the memory size, even if the assembler doesn't need it
    msoAlways = 1,
    // Show memory size if a human can't figure out the size of the operand
    msoMinimal = 2,
    // Never show memory size
    msoNever = 3
  );

var
  Formatter_GetMemorySizeOptions : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TMemorySizeOptions; cdecl;

  // Options that control if the memory size ( eg. `DWORD PTR` ) is shown or not.
  // This is ignored by the gas ( AT&T ) formatter.
  //
  // - Default: [`Default`]
  //
  // [`Default`]: enum.MemorySizeOptions.html#variant.Default
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetMemorySizeOptions : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TMemorySizeOptions ) : boolean; cdecl;

  // Show `RIP+displ` or the virtual address
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rip+12345678h]`
  // X | `false` | `mov eax,[1029384756AFBECDh]`
  Formatter_GetRipRelativeAddresses : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Show `RIP+displ` or the virtual address
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[rip+12345678h]`
  // X | `false` | `mov eax,[1029384756AFBECDh]`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetRipRelativeAddresses : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Show `NEAR`, `SHORT`, etc if it's a branch instruction
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je short 1234h`
  // _ | `false` | `je 1234h`
  Formatter_GetShowBranchSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Show `NEAR`, `SHORT`, etc if it's a branch instruction
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `je short 1234h`
  // _ | `false` | `je 1234h`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetShowBranchSize : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Use pseudo instructions
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `vcmpnltsd xmm2,xmm6,xmm3`
  // _ | `false` | `vcmpsd xmm2,xmm6,xmm3,5`
  Formatter_GetUsePseudoOps : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Use pseudo instructions
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `vcmpnltsd xmm2,xmm6,xmm3`
  // _ | `false` | `vcmpsd xmm2,xmm6,xmm3,5`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetUsePseudoOps : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Show the original value after the symbol name
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,[myfield ( 12345678 )]`
  // X | `false` | `mov eax,[myfield]`
  Formatter_GetShowSymbolAddress : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

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
  Formatter_SetShowSymbolAddress : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // ( gas only ) : If `true`, the formatter doesn't add `%` to registers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ecx`
  // X | `false` | `mov %eax,%ecx`
  GasFormatter_GetNakedRegisters : function( Formatter: Pointer ) : boolean; cdecl;

  // ( gas only ) : If `true`, the formatter doesn't add `%` to registers
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `mov eax,ecx`
  // X | `false` | `mov %eax,%ecx`
  //
  // # Arguments
  // * `value`: New value
  GasFormatter_SetNakedRegisters : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // ( gas only ) : Shows the mnemonic size suffix even when not needed
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `movl %eax,%ecx`
  // X | `false` | `mov %eax,%ecx`
  GasFormatter_GetShowMnemonicSizeSuffix : function( Formatter: Pointer ) : boolean; cdecl;

  // ( gas only ) : Shows the mnemonic size suffix even when not needed
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `movl %eax,%ecx`
  // X | `false` | `mov %eax,%ecx`
  //
  // # Arguments
  // * `value`: New value
  GasFormatter_SetShowMnemonicSizeSuffix : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // ( gas only ) : Add a space after the comma if it's a memory operand
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `( %eax, %ecx, 2 )`
  // X | `false` | `( %eax,%ecx,2 )`
  GasFormatter_GetSpaceAfterMemoryOperandComma : function( Formatter: Pointer ) : boolean; cdecl;

  // ( gas only ) : Add a space after the comma if it's a memory operand
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `( %eax, %ecx, 2 )`
  // X | `false` | `( %eax,%ecx,2 )`
  //
  // # Arguments
  // * `value`: New value
  GasFormatter_SetSpaceAfterMemoryOperandComma : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // ( masm only ) : Add a `DS` segment override even if it's not present. Used if it's 16/32-bit code and mem op is a displ
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov eax,ds:[12345678]`
  // _ | `false` | `mov eax,[12345678]`
  MasmFormatter_GetAddDsPrefix32 : function( Formatter: Pointer ) : boolean; cdecl;

  // ( masm only ) : Add a `DS` segment override even if it's not present. Used if it's 16/32-bit code and mem op is a displ
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `mov eax,ds:[12345678]`
  // _ | `false` | `mov eax,[12345678]`
  //
  // # Arguments
  // * `value`: New value
  MasmFormatter_SetAddDsPrefix32 : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // ( masm only ) : Show symbols in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+symbol]` / `[symbol]`
  // _ | `false` | `symbol[ecx]` / `symbol`
  MasmFormatter_GetSymbolDisplacementInBrackets : function( Formatter: Pointer ) : boolean; cdecl;

  // ( masm only ) : Show symbols in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+symbol]` / `[symbol]`
  // _ | `false` | `symbol[ecx]` / `symbol`
  //
  // # Arguments
  // * `value`: New value
  MasmFormatter_SetSymbolDisplacementInBrackets : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // ( masm only ) : Show displacements in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+1234h]`
  // _ | `false` | `1234h[ecx]`
  MasmFormatter_GetDisplacementInBrackets : function( Formatter: Pointer ) : boolean; cdecl;

  // ( masm only ) : Show displacements in brackets
  //
  // Default | Value | Example
  // --------|-------|--------
  // X | `true` | `[ecx+1234h]`
  // _ | `false` | `1234h[ecx]`
  //
  // # Arguments
  // * `value`: New value
  MasmFormatter_SetDisplacementInBrackets : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // ( nasm only ) : Shows `BYTE`, `WORD`, `DWORD` or `QWORD` if it's a sign extended immediate operand value
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `or rcx,byte -1`
  // X | `false` | `or rcx,-1`
  NasmFormatter_GetShowSignExtendedImmediateSize : function( Formatter: Pointer ) : boolean; cdecl;

  // ( nasm only ) : Shows `BYTE`, `WORD`, `DWORD` or `QWORD` if it's a sign extended immediate operand value
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `or rcx,byte -1`
  // X | `false` | `or rcx,-1`
  //
  // # Arguments
  // * `value`: New value
  NasmFormatter_SetShowSignExtendedImmediateSize : function( Formatter: Pointer; Value : Boolean ) : Boolean; cdecl;

  // Use `st( 0 )` instead of `st` if `st` can be used. Ignored by the nasm formatter.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `fadd st( 0 ),st( 3 )`
  // X | `false` | `fadd st,st( 3 )`
  Formatter_GetPreferST0 : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Use `st( 0 )` instead of `st` if `st` can be used. Ignored by the nasm formatter.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `fadd st( 0 ),st( 3 )`
  // X | `false` | `fadd st,st( 3 )`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetPreferST0 : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Show useless prefixes. If it has useless prefixes, it could be data and not code.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `es rep add eax,ecx`
  // X | `false` | `add eax,ecx`
  Formatter_GetShowUselessPrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : boolean; cdecl;

  // Show useless prefixes. If it has useless prefixes, it could be data and not code.
  //
  // Default | Value | Example
  // --------|-------|--------
  // _ | `true` | `es rep add eax,ecx`
  // X | `false` | `add eax,ecx`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetShowUselessPrefixes : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : Boolean ) : Boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JB` / `JC` / `JNAE` )
  //
  // Default: `JB`, `CMOVB`, `SETB`
type
  TCC_b = (
    // `JB`, `CMOVB`, `SETB`
    b = 0,
    // `JC`, `CMOVC`, `SETC`
    c = 1,
    // `JNAE`, `CMOVNAE`, `SETNAE`
    nae = 2
  );

var
  Formatter_GetCC_b : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_b; cdecl;

  // Mnemonic condition code selector ( eg. `JB` / `JC` / `JNAE` )
  //
  // Default: `JB`, `CMOVB`, `SETB`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_b : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_b ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JAE` / `JNB` / `JNC` )
  //
  // Default: `JAE`, `CMOVAE`, `SETAE`
type
  TCC_ae = (
    // `JAE`, `CMOVAE`, `SETAE`
    ae = 0,
    // `JNB`, `CMOVNB`, `SETNB`
    nb = 1,
    // `JNC`, `CMOVNC`, `SETNC`
    nc = 2
  );

var
  Formatter_GetCC_ae : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_ae; cdecl;

  // Mnemonic condition code selector ( eg. `JAE` / `JNB` / `JNC` )
  //
  // Default: `JAE`, `CMOVAE`, `SETAE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_ae : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_ae ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JE` / `JZ` )
  //
  // Default: `JE`, `CMOVE`, `SETE`, `LOOPE`, `REPE`
type
  TCC_e = (
    // `JE`, `CMOVE`, `SETE`, `LOOPE`, `REPE`
    e = 0,
    // `JZ`, `CMOVZ`, `SETZ`, `LOOPZ`, `REPZ`
    z = 1
  );

var
  Formatter_GetCC_e : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_e; cdecl;

  // Mnemonic condition code selector ( eg. `JE` / `JZ` )
  //
  // Default: `JE`, `CMOVE`, `SETE`, `LOOPE`, `REPE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_e : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_e ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JNE` / `JNZ` )
  //
  // Default: `JNE`, `CMOVNE`, `SETNE`, `LOOPNE`, `REPNE`
type
  TCC_ne = (
    // `JNE`, `CMOVNE`, `SETNE`, `LOOPNE`, `REPNE`
    ne = 0,
    // `JNZ`, `CMOVNZ`, `SETNZ`, `LOOPNZ`, `REPNZ`
    nz = 1
  );

var
  Formatter_GetCC_ne : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_ne; cdecl;

  // Mnemonic condition code selector ( eg. `JNE` / `JNZ` )
  //
  // Default: `JNE`, `CMOVNE`, `SETNE`, `LOOPNE`, `REPNE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_ne : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_ne ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JBE` / `JNA` )
  //
  // Default: `JBE`, `CMOVBE`, `SETBE`
type
  TCC_be = (
    // `JBE`, `CMOVBE`, `SETBE`
    be = 0,
    // `JNA`, `CMOVNA`, `SETNA`
    na = 1
  );

var
  Formatter_GetCC_be : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_be; cdecl;

  // Mnemonic condition code selector ( eg. `JBE` / `JNA` )
  //
  // Default: `JBE`, `CMOVBE`, `SETBE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_be : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_be ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JA` / `JNBE` )
  //
  // Default: `JA`, `CMOVA`, `SETA`
type
  TCC_a = (
    // `JA`, `CMOVA`, `SETA`
    a = 0,
    // `JNBE`, `CMOVNBE`, `SETNBE`
    nbe = 1
  );

var
  Formatter_GetCC_a : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_a; cdecl;

  // Mnemonic condition code selector ( eg. `JA` / `JNBE` )
  //
  // Default: `JA`, `CMOVA`, `SETA`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_a : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_a ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JP` / `JPE` )
  //
  // Default: `JP`, `CMOVP`, `SETP`
type
  TCC_p = (
    // `JP`, `CMOVP`, `SETP`
    p = 0,
    // `JPE`, `CMOVPE`, `SETPE`
    pe = 1
  );

var
  Formatter_GetCC_p : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_p; cdecl;

  // Mnemonic condition code selector ( eg. `JP` / `JPE` )
  //
  // Default: `JP`, `CMOVP`, `SETP`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_p : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_p ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JNP` / `JPO` )
  //
  // Default: `JNP`, `CMOVNP`, `SETNP`
type
  TCC_np = (
    // `JNP`, `CMOVNP`, `SETNP`
    np = 0,
    // `JPO`, `CMOVPO`, `SETPO`
    po = 1
  );

var
  Formatter_GetCC_np : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_np; cdecl;

  // Mnemonic condition code selector ( eg. `JNP` / `JPO` )
  //
  // Default: `JNP`, `CMOVNP`, `SETNP`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_np : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_np ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JL` / `JNGE` )
  //
  // Default: `JL`, `CMOVL`, `SETL`
type
  TCC_l = (
    // `JL`, `CMOVL`, `SETL`
    l = 0,
    // `JNGE`, `CMOVNGE`, `SETNGE`
    nge = 1
  );

var
  Formatter_GetCC_l : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_l; cdecl;

  // Mnemonic condition code selector ( eg. `JL` / `JNGE` )
  //
  // Default: `JL`, `CMOVL`, `SETL`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_l : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_l ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JGE` / `JNL` )
  //
  // Default: `JGE`, `CMOVGE`, `SETGE`
type
  TCC_ge = (
    // `JGE`, `CMOVGE`, `SETGE`
    ge = 0,
    // `JNL`, `CMOVNL`, `SETNL`
    nl = 1
  );

var
  Formatter_GetCC_ge : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_ge; cdecl;

  // Mnemonic condition code selector ( eg. `JGE` / `JNL` )
  //
  // Default: `JGE`, `CMOVGE`, `SETGE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_ge : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_ge ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JLE` / `JNG` )
  //
  // Default: `JLE`, `CMOVLE`, `SETLE`
type
  TCC_le = (
    // `JLE`, `CMOVLE`, `SETLE`
    le = 0,
    // `JNG`, `CMOVNG`, `SETNG`
    ng = 1
  );

var
  Formatter_GetCC_le : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_le; cdecl;

  // Mnemonic condition code selector ( eg. `JLE` / `JNG` )
  //
  // Default: `JLE`, `CMOVLE`, `SETLE`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_le : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_le ) : boolean; cdecl;

  // Mnemonic condition code selector ( eg. `JG` / `JNLE` )
  //
  // Default: `JG`, `CMOVG`, `SETG`
type
  TCC_g = (
    // `JG`, `CMOVG`, `SETG`
    g = 0,
    // `JNLE`, `CMOVNLE`, `SETNLE`
    nle = 1
  );

var
  Formatter_GetCC_g : function( Formatter: Pointer; FormatterType : TIcedFormatterType ) : TCC_g; cdecl;

  // Mnemonic condition code selector ( eg. `JG` / `JNLE` )
  //
  // Default: `JG`, `CMOVG`, `SETG`
  //
  // # Arguments
  // * `value`: New value
  Formatter_SetCC_g : function( Formatter: Pointer; FormatterType : TIcedFormatterType; Value : TCC_g ) : boolean; cdecl;


  // Encoder
  // Creates an encoder
  //
  // Returns NULL if `bitness` is not one of 16, 32, 64.
  //
  // # Arguments
  // * `bitness`: 16, 32 or 64
  // * `capacity`: Initial capacity of the `u8` buffer
  Encoder_Create : function( Bitness : Cardinal; Capacity : NativeUInt = 0 ) : Pointer; cdecl;

  // Encodes an instruction and returns the size of the encoded instruction
  //
  // # Result
  // * Returns written amount of encoded Bytes
  //
  // # Arguments
  // * `instruction`: Instruction to encode
  // * `rip`: `RIP` of the encoded instruction
  Encoder_Encode : function( Encoder : Pointer; var Instruction : TInstruction ) : NativeUInt; cdecl;

  // Writes a byte to the output buffer
  //
  // # Arguments
  //
  // `value`: Value to write
  Encoder_WriteByte : function ( Encoder : Pointer; Value : Byte ) : boolean; cdecl;

  // Returns the buffer and initializes the internal buffer to an empty vector. Should be called when
  // you've encoded all instructions and need the raw instruction bytes. See also [`set_buffer()`].
  Encoder_GetBuffer : function ( Encoder : Pointer; Value : PByte; Size : NativeUInt ) : boolean; cdecl;

  // Overwrites the buffer with a new vector. The old buffer is dropped. See also [`Encoder_GetBuffer`].
  // NOTE: Monitor the result of [`Encoder_Encode`] (Encoded Bytes).
  // DO NOT Encode more Bytes than fitting your provided Buffer as this would cause a realloc - which will lead to an access violation.
//  Encoder_SetBuffer : function ( Encoder : Pointer; Value : PByte; Size : NativeUInt ) : boolean; cdecl;

  // Gets the offsets of the constants (memory displacement and immediate) in the encoded instruction.
  // The caller can use this information to add relocations if needed.
  Encoder_GetConstantOffsets : procedure( Decoder : Pointer; var ConstantOffsets : TConstantOffsets ); cdecl;

  // Disables 2-byte VEX encoding and encodes all VEX instructions with the 3-byte VEX encoding
  Encoder_GetPreventVex2 : function( Encoder : Pointer ) : Boolean; cdecl;

  // Disables 2-byte VEX encoding and encodes all VEX instructions with the 3-byte VEX encoding
  //
  // # Arguments
  // * `new_value`: new value
  Encoder_SetPreventVex2 : function ( Encoder : Pointer; Value : Boolean ) : boolean; cdecl;

  // Value of the `VEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetVexWig : function( Encoder : Pointer ) : Cardinal; cdecl;

  // Value of the `VEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetVexWig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl;

  // Value of the `VEX.L` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetVexLig : function( Encoder : Pointer ) : Cardinal; cdecl;

  // Value of the `VEX.L` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetVexLig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl;

  // Value of the `EVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetEvexWig : function( Encoder : Pointer ) : Cardinal; cdecl;

  // Value of the `EVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetEvexWig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl;

  // Value of the `EVEX.L'L` bits to use if it's an instruction that ignores the bits. Default is 0.
  Encoder_GetEvexLig : function( Encoder : Pointer ) : Cardinal; cdecl;

  // Value of the `EVEX.L'L` bits to use if it's an instruction that ignores the bits. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 3)
  Encoder_SetEvexLig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl;

  // Value of the `MVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  Encoder_GetMvexWig : function( Encoder : Pointer ) : Cardinal; cdecl;

  // Value of the `MVEX.W` bit to use if it's an instruction that ignores the bit. Default is 0.
  //
  // # Arguments
  // * `new_value`: new value (0 or 1)
  Encoder_SetMvexWig : function ( Encoder : Pointer; Value : Cardinal ) : boolean; cdecl;

  // Gets the bitness (16, 32 or 64)
  Encoder_GetBitness : function( Encoder : Pointer ) : Cardinal; cdecl;

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
  BlockEncoder : function( Bitness : Cardinal; RIP : UInt64; var Instructions : TInstruction; Count : NativeUInt; var Result : TBlockEncoderResult; Options : Cardinal = beoNONE ) : Pointer; cdecl;

  // Instruction
  // Gets the FPU status word's `TOP` increment and whether it's a conditional or unconditional push/pop
  // and whether `TOP` is written.
  Instruction_FPU_StackIncrementInfo : function( var Instruction : TInstruction; var Info : TFpuStackIncrementInfo ) : Boolean; cdecl;

  // Instruction encoding, eg. Legacy, 3DNow!, VEX, EVEX, XOP
  Instruction_Encoding : function( var Instruction : TInstruction ) : TEncodingKind; cdecl;

  // Gets the mnemonic, see also [`code()`]
  Instruction_Mnemonic : function( var Instruction : TInstruction ) : TMnemonic; cdecl;

  // Gets the CPU or CPUID feature flags
  Instruction_CPUIDFeatures : function( var Instruction : TInstruction; var CPUIDFeatures : TCPUIDFeaturesArray ) : Boolean; cdecl;

  // `true` if this is an instruction that implicitly uses the stack pointer (`SP`/`ESP`/`RSP`), eg. `CALL`, `PUSH`, `POP`, `RET`, etc.
  // See also [`stack_pointer_increment()`]
  //
  // [`stack_pointer_increment()`]: #method.stack_pointer_increment
  Instruction_IsStackInstruction : function( var Instruction : TInstruction ) : Boolean; cdecl;

  // Gets the number of bytes added to `SP`/`ESP`/`RSP` or 0 if it's not an instruction that pushes or pops data. This method assumes
  // the instruction doesn't change the privilege level (eg. `IRET/D/Q`). If it's the `LEAVE` instruction, this method returns 0.
  Instruction_StackPointerIncrement : function( var Instruction : TInstruction ) : Integer; cdecl;

  // Gets the condition code if it's `Jcc`, `SETcc`, `CMOVcc`, `LOOPcc` else [`ConditionCode::None`] is returned
  //
  // [`ConditionCode::None`]: enum.ConditionCode.html#variant.None
  Instruction_ConditionCode : function( var Instruction : TInstruction ) : TConditionCode; cdecl;

  // All flags that are read by the CPU when executing the instruction.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsRead : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl;

  // All flags that are written by the CPU, except those flags that are known to be undefined, always set or always cleared.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsWritten : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl;

  // All flags that are always cleared by the CPU.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsCleared : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl;

  // All flags that are always set by the CPU.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsSet : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl;

  // All flags that are undefined after executing the instruction.
  // This method returns an [`RflagsBits`] value. See also [`rflags_modified()`].
  Instruction_RFlagsUndefined : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl;

  // All flags that are modified by the CPU. This is `rflags_written() + rflags_cleared() + rflags_set() + rflags_undefined()`. This method returns an [`RflagsBits`] value.
  Instruction_RFlagsModified : function( var Instruction : TInstruction ) : TRFlag{Cardinal}; cdecl;

  // Control flow info
  Instruction_FlowControl : function( var Instruction : TInstruction ) : TFlowControl; cdecl;

  // Gets all op kinds ([`op_count()`] values)
  Instruction_OPKinds : function( var Instruction : TInstruction; var OPKindsArray : TOPKindsArray ) : TFlowControl; cdecl;

  // Gets the size of the memory location that is referenced by the operand. See also [`is_broadcast()`].
  // Use this method if the operand has kind [`OpKind::Memory`],
  Instruction_MemorySize : function( var Instruction : TInstruction ) : Byte; cdecl;

  // Gets the operand count. An instruction can have 0-5 operands.
  Instruction_OPCount : function( var Instruction : TInstruction ) : Cardinal; cdecl;

  // OpCodeInfo
  // Gets the code
  Instruction_OpCodeInfo_Code : function( var Instruction : TInstruction ) : TCode; cdecl;

  // Gets the mnemonic
  Instruction_OpCodeInfo_Mnemonic : function( var Instruction : TInstruction ) : TMnemonic; cdecl;

  // `true` if it's an instruction, `false` if it's eg. [`Code::INVALID`], [`db`], [`dw`], [`dd`], [`dq`], [`zero_bytes`]
  Instruction_OpCodeInfo_IsInstruction : function( var Instruction : TInstruction ) : Boolean; cdecl;

  // `true` if it's an instruction available in 16-bit mode
  Instruction_OpCodeInfo_Mode16 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's an instruction available in 32-bit mode
  Instruction_OpCodeInfo_Mode32 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's an instruction available in 64-bit mode
  Instruction_OpCodeInfo_Mode64 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if an `FWAIT` (`9B`) instruction is added before the instruction
  Instruction_OpCodeInfo_Fwait : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (Legacy encoding) Gets the required operand size (16,32,64) or 0
  Instruction_OpCodeInfo_OperandSize : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // (Legacy encoding) Gets the required address size (16,32,64) or 0
  Instruction_OpCodeInfo_AddressSize : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // (VEX/XOP/EVEX) `L` / `L'L` value or default value if [`is_lig()`] is `true`
  Instruction_OpCodeInfo_L : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // (VEX/XOP/EVEX/MVEX) `W` value or default value if [`is_wig()`] or [`is_wig32()`] is `true`
  Instruction_OpCodeInfo_W : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // (VEX/XOP/EVEX) `true` if the `L` / `L'L` fields are ignored.
  //
  // EVEX: if reg-only ops and `{er}` (`EVEX.b` is set), `L'L` is the rounding control and not ignored.
  Instruction_OpCodeInfo_IsLig : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (VEX/XOP/EVEX/MVEX) `true` if the `W` field is ignored in 16/32/64-bit modes
  Instruction_OpCodeInfo_IsWig : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (VEX/XOP/EVEX/MVEX) `true` if the `W` field is ignored in 16/32-bit modes (but not 64-bit mode)
  Instruction_OpCodeInfo_IsWig32 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (EVEX/MVEX) Gets the tuple type
  Instruction_OpCodeInfo_TupleType : function( var Instruction: TInstruction ) : TTupleType; cdecl;

  // (MVEX) Gets the `EH` bit that's required to encode this instruction
  Instruction_OpCodeInfo_MvexEhBit : function( var Instruction: TInstruction ) : TMvexEHBit; cdecl;

  // (MVEX) `true` if the instruction supports eviction hint (if it has a memory operand)
  Instruction_OpCodeInfo_MvexCanUseEvictionHint : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (MVEX) `true` if the instruction's rounding control bits are stored in `imm8[1:0]`
  Instruction_OpCodeInfo_MvexCanUseImmRoundingControl : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (MVEX) `true` if the instruction ignores op mask registers (eg. `{k1}`)
  Instruction_OpCodeInfo_MvexIgnoresOpMaskRegister : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (MVEX) `true` if the instruction must have `MVEX.SSS=000` if `MVEX.EH=1`
  Instruction_OpCodeInfo_MvexNoSaeRc : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (MVEX) Gets the tuple type / conv lut kind
  Instruction_OpCodeInfo_MvexTupleTypeLutKind : function( var Instruction: TInstruction ) : TMvexTupleTypeLutKind; cdecl;

  // (MVEX) Gets the conversion function, eg. `Sf32`
  Instruction_OpCodeInfo_MvexConversionFunc : function( var Instruction: TInstruction ) : TMvexConvFn; cdecl;

  // (MVEX) Gets flags indicating which conversion functions are valid (bit 0 == func 0)
  Instruction_OpCodeInfo_MvexValidConversionFuncsMask : function( var Instruction: TInstruction ) : Byte; cdecl;

  // (MVEX) Gets flags indicating which swizzle functions are valid (bit 0 == func 0)
  Instruction_OpCodeInfo_MvexValidSwizzleFuncsMask : function( var Instruction: TInstruction ) : Byte; cdecl;

  // If it has a memory operand, gets the [`MemorySize`] (non-broadcast memory type)
  Instruction_OpCodeInfo_MemorySize : function( var Instruction: TInstruction ) : TMemorySize; cdecl;

  // If it has a memory operand, gets the [`MemorySize`] (broadcast memory type)
  Instruction_OpCodeInfo_BroadcastMemorySize : function( var Instruction: TInstruction ) : TMemorySize; cdecl;

  // (EVEX) `true` if the instruction supports broadcasting (`EVEX.b` bit) (if it has a memory operand)
  Instruction_OpCodeInfo_CanBroadcast : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (EVEX/MVEX) `true` if the instruction supports rounding control
  Instruction_OpCodeInfo_CanUseRoundingControl : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (EVEX/MVEX) `true` if the instruction supports suppress all exceptions
  Instruction_OpCodeInfo_CanSuppressAllExceptions : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (EVEX/MVEX) `true` if an opmask register can be used
  Instruction_OpCodeInfo_CanUseOpMaskRegister : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (EVEX/MVEX) `true` if a non-zero opmask register must be used
  Instruction_OpCodeInfo_RequireOpMaskRegister : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (EVEX) `true` if the instruction supports zeroing masking (if one of the opmask registers `K1`-`K7` is used and destination operand is not a memory operand)
  Instruction_OpCodeInfo_CanUseZeroingMasking : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `LOCK` (`F0`) prefix can be used
  Instruction_OpCodeInfo_CanUseLockPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `XACQUIRE` (`F2`) prefix can be used
  Instruction_OpCodeInfo_CanUseXacquirePrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `XRELEASE` (`F3`) prefix can be used
  Instruction_OpCodeInfo_CanUseXreleasePrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `REP` / `REPE` (`F3`) prefixes can be used
  Instruction_OpCodeInfo_CanUseRepPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `REPNE` (`F2`) prefix can be used
  Instruction_OpCodeInfo_CanUseRepnePrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `BND` (`F2`) prefix can be used
  Instruction_OpCodeInfo_CanUseBndPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `HINT-TAKEN` (`3E`) and `HINT-NOT-TAKEN` (`2E`) prefixes can be used
  Instruction_OpCodeInfo_CanUseHintTakenPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `NOTRACK` (`3E`) prefix can be used
  Instruction_OpCodeInfo_CanUseNotrackPrefix : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if rounding control is ignored (#UD is not generated)
  Instruction_OpCodeInfo_IgnoresRoundingControl : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `LOCK` prefix can be used as an extra register bit (bit 3) to access registers 8-15 without a `REX` prefix (eg. in 32-bit mode)
  Instruction_OpCodeInfo_AmdLockRegBit : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the default operand size is 64 in 64-bit mode. A `66` prefix can switch to 16-bit operand size.
  Instruction_OpCodeInfo_DefaultOpSize64 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the operand size is always 64 in 64-bit mode. A `66` prefix is ignored.
  Instruction_OpCodeInfo_ForceOpSize64 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the Intel decoder forces 64-bit operand size. A `66` prefix is ignored.
  Instruction_OpCodeInfo_IntelForceOpSize64 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can only be executed when CPL=0
  Instruction_OpCodeInfo_MustBeCpl0 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed when CPL=0
  Instruction_OpCodeInfo_Cpl0 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed when CPL=1
  Instruction_OpCodeInfo_Cpl1 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed when CPL=2
  Instruction_OpCodeInfo_Cpl2 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed when CPL=3
  Instruction_OpCodeInfo_Cpl3 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the instruction accesses the I/O address space (eg. `IN`, `OUT`, `INS`, `OUTS`)
  Instruction_OpCodeInfo_IsInputOutput : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's one of the many nop instructions (does not include FPU nop instructions, eg. `FNOP`)
  Instruction_OpCodeInfo_IsNop : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's one of the many reserved nop instructions (eg. `0F0D`, `0F18-0F1F`)
  Instruction_OpCodeInfo_IsReservedNop : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's a serializing instruction (Intel CPUs)
  Instruction_OpCodeInfo_IsSerializingIntel : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's a serializing instruction (AMD CPUs)
  Instruction_OpCodeInfo_IsSerializingAmd : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the instruction requires either CPL=0 or CPL<=3 depending on some CPU option (eg. `CR4.TSD`, `CR4.PCE`, `CR4.UMIP`)
  Instruction_OpCodeInfo_MayRequireCpl0 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's a tracked `JMP`/`CALL` indirect instruction (CET)
  Instruction_OpCodeInfo_IsCetTracked : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's a non-temporal hint memory access (eg. `MOVNTDQ`)
  Instruction_OpCodeInfo_IsNonTemporal : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's a no-wait FPU instruction, eg. `FNINIT`
  Instruction_OpCodeInfo_IsFpuNoWait : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the mod bits are ignored and it's assumed `modrm[7:6] == 11b`
  Instruction_OpCodeInfo_IgnoresModBits : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `66` prefix is not allowed (it will #UD)
  Instruction_OpCodeInfo_No66 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the `F2`/`F3` prefixes aren't allowed
  Instruction_OpCodeInfo_Nfx : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the index reg's reg-num (vsib op) (if any) and register ops' reg-nums must be unique,
  // eg. `MNEMONIC XMM1,YMM1,[RAX+ZMM1*2]` is invalid. Registers = `XMM`/`YMM`/`ZMM`/`TMM`.
  Instruction_OpCodeInfo_RequiresUniqueRegNums : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the destination register's reg-num must not be present in any other operand, eg. `MNEMONIC XMM1,YMM1,[RAX+ZMM1*2]`
  // is invalid. Registers = `XMM`/`YMM`/`ZMM`/`TMM`.
  Instruction_OpCodeInfo_RequiresUniqueDestRegNum : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's a privileged instruction (all CPL=0 instructions (except `VMCALL`) and IOPL instructions `IN`, `INS`, `OUT`, `OUTS`, `CLI`, `STI`)
  Instruction_OpCodeInfo_IsPrivileged : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it reads/writes too many registers
  Instruction_OpCodeInfo_IsSaveRestore : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's an instruction that implicitly uses the stack register, eg. `CALL`, `POP`, etc
  Instruction_OpCodeInfo_IsStackInstruction : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the instruction doesn't read the segment register if it uses a memory operand
  Instruction_OpCodeInfo_IgnoresSegment : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if the opmask register is read and written (instead of just read). This also implies that it can't be `K0`.
  Instruction_OpCodeInfo_IsOpMaskReadWrite : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed in real mode
  Instruction_OpCodeInfo_RealMode : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed in protected mode
  Instruction_OpCodeInfo_ProtectedMode : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed in virtual 8086 mode
  Instruction_OpCodeInfo_Virtual8086Mode : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed in compatibility mode
  Instruction_OpCodeInfo_CompatibilityMode : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be executed in 64-bit mode
  Instruction_OpCodeInfo_LongMode : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used outside SMM
  Instruction_OpCodeInfo_UseOutsideSmm : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used in SMM
  Instruction_OpCodeInfo_UseInSmm : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used outside an enclave (SGX)
  Instruction_OpCodeInfo_UseOutsideEnclaveSgx : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used inside an enclave (SGX1)
  Instruction_OpCodeInfo_UseInEnclaveSgx1 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used inside an enclave (SGX2)
  Instruction_OpCodeInfo_UseInEnclaveSgx2 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used outside VMX operation
  Instruction_OpCodeInfo_UseOutsideVmxOp : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used in VMX root operation
  Instruction_OpCodeInfo_UseInVmxRootOp : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used in VMX non-root operation
  Instruction_OpCodeInfo_UseInVmxNonRootOp : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used outside SEAM
  Instruction_OpCodeInfo_UseOutsideSeam : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it can be used in SEAM
  Instruction_OpCodeInfo_UseInSeam : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if #UD is generated in TDX non-root operation
  Instruction_OpCodeInfo_TdxNonRootGenUd : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if #VE is generated in TDX non-root operation
  Instruction_OpCodeInfo_TdxNonRootGenVe : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if an exception (eg. #GP(0), #VE) may be generated in TDX non-root operation
  Instruction_OpCodeInfo_TdxNonRootMayGenEx : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (Intel VMX) `true` if it causes a VM exit in VMX non-root operation
  Instruction_OpCodeInfo_IntelVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (Intel VMX) `true` if it may cause a VM exit in VMX non-root operation
  Instruction_OpCodeInfo_IntelMayVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (Intel VMX) `true` if it causes an SMM VM exit in VMX root operation (if dual-monitor treatment is activated)
  Instruction_OpCodeInfo_IntelSmmVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (AMD SVM) `true` if it causes a #VMEXIT in guest mode
  Instruction_OpCodeInfo_AmdVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // (AMD SVM) `true` if it may cause a #VMEXIT in guest mode
  Instruction_OpCodeInfo_AmdMayVMExit : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it causes a TSX abort inside a TSX transaction
  Instruction_OpCodeInfo_TsxAbort : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it causes a TSX abort inside a TSX transaction depending on the implementation
  Instruction_OpCodeInfo_TsxImplAbort : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it may cause a TSX abort inside a TSX transaction depending on some condition
  Instruction_OpCodeInfo_TsxMayAbort : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's decoded by iced's 16-bit Intel decoder
  Instruction_OpCodeInfo_IntelDecoder16 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's decoded by iced's 32-bit Intel decoder
  Instruction_OpCodeInfo_IntelDecoder32 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's decoded by iced's 64-bit Intel decoder
  Instruction_OpCodeInfo_IntelDecoder64 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's decoded by iced's 16-bit AMD decoder
  Instruction_OpCodeInfo_AmdDecoder16 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's decoded by iced's 32-bit AMD decoder
  Instruction_OpCodeInfo_AmdDecoder32 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // `true` if it's decoded by iced's 64-bit AMD decoder
  Instruction_OpCodeInfo_AmdDecoder64 : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // Gets the decoder option that's needed to decode the instruction or [`DecoderOptions::NONE`].
  // The return value is a [`DecoderOptions`] value.
  Instruction_OpCodeInfo_DecoderOption : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // Gets the opcode table
  Instruction_OpCodeInfo_Table : function( var Instruction: TInstruction ) : TOpCodeTableKind; cdecl;

  // Gets the mandatory prefix
  Instruction_OpCodeInfo_MandatoryPrefix : function( var Instruction: TInstruction ) : TMandatoryPrefix; cdecl;

  // Gets the opcode byte(s). The low byte(s) of this value is the opcode. The length is in [`op_code_len()`].
  // It doesn't include the table value, see [`table()`].
  Instruction_OpCodeInfo_OpCode : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // Gets the length of the opcode bytes ([`op_code()`]). The low bytes is the opcode value.
  Instruction_OpCodeInfo_OpCodeLen : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // `true` if it's part of a group
  Instruction_OpCodeInfo_IsGroup : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // Group index (0-7) or -1. If it's 0-7, it's stored in the `reg` field of the `modrm` byte.
  Instruction_OpCodeInfo_GroupIndex : function( var Instruction: TInstruction ) : Integer; cdecl;

  // `true` if it's part of a modrm.rm group
  Instruction_OpCodeInfo_IsRMGroup : function( var Instruction: TInstruction ) : Boolean; cdecl;

  // Group index (0-7) or -1. If it's 0-7, it's stored in the `rm` field of the `modrm` byte.
  Instruction_OpCodeInfo_RMGroupIndex : function( var Instruction: TInstruction ) : Integer; cdecl;

  // Gets the number of operands
  Instruction_OpCodeInfo_OPCount : function( var Instruction: TInstruction ) : Cardinal; cdecl;

  // Gets operand #0's opkind
  Instruction_OpCodeInfo_OP0Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl;

  // Gets operand #1's opkind
  Instruction_OpCodeInfo_OP1Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl;

  // Gets operand #2's opkind
  Instruction_OpCodeInfo_OP2Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl;

  // Gets operand #3's opkind
  Instruction_OpCodeInfo_OP3Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl;

  // Gets operand #4's opkind
  Instruction_OpCodeInfo_OP4Kind : function( var Instruction: TInstruction ) : TOpCodeOperandKind; cdecl;

  // Gets an operand's opkind
  //
  // # Arguments
  //
  // * `operand`: Operand number, 0-4
  Instruction_OpCodeInfo_OPKind : function( var Instruction: TInstruction; operand: Cardinal ) : TOpCodeOperandKind; cdecl;

  // Gets all operand kinds
  Instruction_OpCodeInfo_OPKinds : function( var Instruction: TInstruction; var OPKinds : TOPCodeOperandKindArray ) : Boolean; cdecl;

  // Checks if the instruction is available in 16-bit mode, 32-bit mode or 64-bit mode
  //
  // # Arguments
  //
  // * `bitness`: 16, 32 or 64
  Instruction_OpCodeInfo_IsAvailableInMode : function( var Instruction: TInstruction; Bitness: Cardinal ) : Boolean; cdecl;

  // Gets the opcode string, eg. `VEX.128.66.0F38.W0 78 /r`, see also [`instruction_string()`]
  Instruction_OpCodeInfo_OpCodeString : function( var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ) : Boolean; cdecl;

  // Gets the instruction string, eg. `VPBROADCASTB xmm1, xmm2/m8`, see also [`op_code_string()`]
  Instruction_OpCodeInfo_InstructionString : function( var Instruction: TInstruction; Output: PAnsiChar; Size : NativeUInt ) : Boolean; cdecl;

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
  Instruction_VirtualAddress : function ( var Instruction: TInstruction; Callback : TVirtualAddressResolverCallback; Operand : Cardinal = 0; Index : NativeUInt = 0; UserData : Pointer = nil ) : UInt64; cdecl;

  // InstructionInfoFactory
  // Creates a new instance.
  //
  // If you don't need to know register and memory usage, it's faster to call [`Instruction`] and
  // [`Code`] methods such as [`Instruction::flow_control()`] instead of getting that info from this struct.
  //
  // [`Instruction`]: struct.Instruction.html
  // [`Code`]: enum.Code.html
  // [`Instruction::flow_control()`]: struct.Instruction.html#method.flow_control
  InstructionInfoFactory_Create : function : Pointer; cdecl;

  // Creates a new [`InstructionInfo`], see also [`info()`].
  //
  // If you don't need to know register and memory usage, it's faster to call [`Instruction`] and
  // [`Code`] methods such as [`Instruction::flow_control()`] instead of getting that info from this struct.
  InstructionInfoFactory_Info : function( InstructionInfoFactory : Pointer; var Instruction: TInstruction; var InstructionInfo : TInstructionInfo; Options : Cardinal = iioNone ) : Boolean; cdecl;

  // Instruction 'WITH'
  // Creates an instruction with no operands
  Instruction_With : function( var Instruction : TInstruction; Code : TCode ) : Boolean; cdecl;

  // Creates an instruction with 1 operand
  //
  // # Errors
  // Fails if one of the operands is invalid (basic checks)
  Instruction_With1_Register : function( var Instruction : TInstruction; Code : TCode; Register : TRegister ) : Boolean; cdecl;
  Instruction_With1_i32 : function( var Instruction : TInstruction; Code : TCode; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With1_u32 : function( var Instruction : TInstruction; Code : TCode; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With1_Memory : function( var Instruction : TInstruction; Code : TCode; var Memory : TMemoryOperand ) : Boolean; cdecl;
  Instruction_With2_Register_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister ) : Boolean; cdecl;
  Instruction_With2_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With2_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With2_Register_i64 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : Int64 ) : Boolean; cdecl;
  Instruction_With2_Register_u64 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate : UInt64 ) : Boolean; cdecl;
  Instruction_With2_Register_MemoryOperand : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; var Memory : TMemoryOperand ) : Boolean; cdecl;
  Instruction_With2_i32_Register : function( var Instruction : TInstruction; Code : TCode; Immediate : Integer; Register : TRegister ) : Boolean; cdecl;
  Instruction_With2_u32_Register : function( var Instruction : TInstruction; Code : TCode; Immediate : Cardinal; Register : TRegister ) : Boolean; cdecl;
  Instruction_With2_i32_i32 : function( var Instruction : TInstruction; Code : TCode; Immediate1 : Integer; Immediate2 : Integer ) : Boolean; cdecl;
  Instruction_With2_u32_u32 : function( var Instruction : TInstruction; Code : TCode; Immediate1 : Cardinal; Immediate2 : Cardinal ) : Boolean; cdecl;
  Instruction_With2_MemoryOperand_Register : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register : TRegister ) : Boolean; cdecl;
  Instruction_With2_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With2_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With3_Register_Register_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister ) : Boolean; cdecl;
  Instruction_With3_Register_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With3_Register_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With3_Register_Register_MemoryOperand : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; var Memory : TMemoryOperand ) : Boolean; cdecl;
  Instruction_With3_Register_i32_i32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : Boolean; cdecl;
  Instruction_With3_Register_u32_u32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : Boolean; cdecl;
  Instruction_With3_Register_MemoryOperand_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Register2 : TRegister ) : Boolean; cdecl;
  Instruction_With3_Register_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With3_Register_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Register : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With3_MemoryOperand_Register_Register : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register1 : TRegister; Register2 : TRegister ) : Boolean; cdecl;
  Instruction_With3_MemoryOperand_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register : TRegister; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With3_MemoryOperand_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Memory : TMemoryOperand; Register : TRegister; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With4_Register_Register_Register_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister ) : Boolean; cdecl;
  Instruction_With4_Register_Register_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With4_Register_Register_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With4_Register_Register_Register_MemoryOperand : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; var Memory : TMemoryOperand ) : Boolean; cdecl;
  Instruction_With4_Register_Register_i32_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : Boolean; cdecl;
  Instruction_With4_Register_Register_u32_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : Boolean; cdecl;
  Instruction_With4_Register_Register_MemoryOperand_Register : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister ) : Boolean; cdecl;
  Instruction_With4_Register_Register_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With4_Register_Register_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With5_Register_Register_Register_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With5_Register_Register_Register_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With5_Register_Register_Register_MemoryOperand_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With5_Register_Register_Register_MemoryOperand_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With5_Register_Register_MemoryOperand_Register_i32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Integer ) : Boolean; cdecl;
  Instruction_With5_Register_Register_MemoryOperand_Register_u32 : function( var Instruction : TInstruction; Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Cardinal ) : Boolean; cdecl;
  Instruction_With_Branch : function( var Instruction : TInstruction; Code : TCode; Target : UInt64 ) : Boolean; cdecl;
  Instruction_With_Far_Branch : function( var Instruction : TInstruction; Code : TCode; Selector : Word; Offset : Cardinal ) : Boolean; cdecl;
  Instruction_With_xbegin : function( var Instruction : TInstruction; Bitness : Cardinal; Target : UInt64 ) : Boolean; cdecl;
  Instruction_With_outsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_outsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_outsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_outsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_outsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_outsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_lodsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_lodsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_lodsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_lodsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_lodsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_lodsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_lodsq : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_lodsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_scasb : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_scasb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_scasb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_scasw : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_scasw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_scasw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_scasd : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_scasd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_scasd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_scasq : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_scasq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_scasq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_insb : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_insb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_insw : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_insw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_insd : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_insd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_stosb : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_stosb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_stosw : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_stosw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_stosd : function( var Instruction : TInstruction; AddressSize: Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_stosd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_stosq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_cmpsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_cmpsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_cmpsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_cmpsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_cmpsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_cmpsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_cmpsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_cmpsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_cmpsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_cmpsq : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repe_cmpsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_Repne_cmpsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_movsb : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_movsb : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_movsw : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_movsw : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_movsd : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_movsd : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_movsq : function( var Instruction : TInstruction; AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : Boolean; cdecl;
  Instruction_With_Rep_movsq : function( var Instruction : TInstruction; AddressSize: Cardinal ) : Boolean; cdecl;
  Instruction_With_maskmovq : function( var Instruction : TInstruction; AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : Boolean; cdecl;
  Instruction_With_maskmovdqu : function( var Instruction : TInstruction; AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : Boolean; cdecl;
  Instruction_With_vmaskmovdqu : function( var Instruction : TInstruction; AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_1 : function( var Instruction : TInstruction; B0 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_2 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_3 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_4 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_5 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_6 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_7 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_8 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_9 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_10 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_11 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_12 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_13 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_14 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_15 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Byte_16 : function( var Instruction : TInstruction; B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte; B15 : Byte ) : Boolean; cdecl;
  Instruction_With_Declare_Word_1 : function( var Instruction : TInstruction; W0 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_2 : function( var Instruction : TInstruction; W0 : Word; W1 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_3 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_4 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_5 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_6 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_7 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_Word_8 : function( var Instruction : TInstruction; W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word; W7 : Word ) : Boolean; cdecl;
  Instruction_With_Declare_DWord_1 : function( var Instruction : TInstruction; D0 : Cardinal ) : Boolean; cdecl;
  Instruction_With_Declare_DWord_2 : function( var Instruction : TInstruction; D0 : Cardinal; D1 : Cardinal ) : Boolean; cdecl;
  Instruction_With_Declare_DWord_3 : function( var Instruction : TInstruction; D0 : Cardinal; D1 : Cardinal; D2 : Cardinal ) : Boolean; cdecl;
  Instruction_With_Declare_DWord_4 : function( var Instruction : TInstruction; D0 : Cardinal; D1 : Cardinal; D2 : Cardinal; D3 : Cardinal ) : Boolean; cdecl;
  Instruction_With_Declare_QWord_1 : function( var Instruction : TInstruction; Q0 : UInt64 ) : Boolean; cdecl;
  Instruction_With_Declare_QWord_2 : function( var Instruction : TInstruction; Q0 : UInt64; Q1 : UInt64 ) : Boolean; cdecl;

// Macros
function  Instruction_GetRIP( var Instruction : TInstruction ) : UInt64; {$IF CompilerVersion >= 23}inline;{$IFEND}
procedure Instruction_SetRIP( var Instruction : TInstruction; Value : UInt64 ); {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsValid( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsData( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsProcedureStart( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsJump( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsRegJump( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsConditionalJump( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsCall( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsRet( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  Instruction_IsEqual( var Instruction : TInstruction; var CompareInstruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}

function  ConstantOffsets_HasDisplacement( var Offsets : TConstantOffsets ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  ConstantOffsets_HasImmediate( var Offsets : TConstantOffsets ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
function  ConstantOffsets_HasImmediate2( var Offsets : TConstantOffsets ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}

function  ParseRFlags( RFlags : TRFlag ) : String; overload;
function  ParseRFlags( RFlags : Cardinal ) : String; overload

// Instruction 'WITH'
// Creates an instruction with no operands
function Instruction_With_( Code : TCode ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}

// Creates an instruction with 1 operand
//
// # Errors
// Fails if one of the operands is invalid (basic checks)
function Instruction_With1( Code : TCode; Register_ : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With1( Code : TCode; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With1( Code : TCode; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With1( Code : TCode; Memory : TMemoryOperand ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Register1 : TRegister; Register2 : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : Int64 ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : UInt64 ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Register_ : TRegister; Memory : TMemoryOperand ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Immediate : Integer; Register_ : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Immediate : Cardinal; Register_ : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Immediate1 : Integer; Immediate2 : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Immediate1 : Cardinal; Immediate2 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Memory : TMemoryOperand; Register_ : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With2( Code : TCode; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register_ : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register_ : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Register2 : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Register_ : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Memory : TMemoryOperand; Register1 : TRegister; Register2 : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Memory : TMemoryOperand; Register_ : TRegister; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With3( Code : TCode; Memory : TMemoryOperand; Register_ : TRegister; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Integer ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Branch_( Code : TCode; Target : UInt64 ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Far_Branch_( Code : TCode; Selector : Word; Offset : Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_xbegin_( Bitness : Cardinal; Target : UInt64 ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_outsb_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_outsb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_outsw_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_outsw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_outsd_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_outsd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_lodsb_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_lodsb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_lodsw_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_lodsw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_lodsd_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_lodsd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_lodsq_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_lodsq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_scasb_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_scasb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_scasb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_scasw_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_scasw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_scasw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_scasd_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_scasd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_scasd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_scasq_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_scasq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_scasq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_insb_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_insb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_insw_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_insw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_insd_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_insd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_stosb_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_stosb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_stosw_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_stosw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_stosd_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_stosd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_stosq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_cmpsb_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_cmpsb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_cmpsb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_cmpsw_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_cmpsw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_cmpsw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_cmpsd_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_cmpsd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_cmpsd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_cmpsq_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repe_cmpsq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Repne_cmpsq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_movsb_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_movsb_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_movsw_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_movsw_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_movsd_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_movsd_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_movsq_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Rep_movsq_( AddressSize: Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_maskmovq_( AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_maskmovdqu_( AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_vmaskmovdqu_( AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : TInstruction; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( Bytes : Array of Byte ) : TInstruction; overload;
function Instruction_With_Declare_Byte_( B0 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte; B15 : Byte ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( Words : Array of Word ) : TInstruction; overload;
function Instruction_With_Declare_Word_( W0 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word; W7 : Word ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_DWord_( DWords : Array of Cardinal ) : TInstruction; overload;
function Instruction_With_Declare_DWord_( D0 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_DWord_( D0 : Cardinal; D1 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_DWord_( D0 : Cardinal; D1 : Cardinal; D2 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_DWord_( D0 : Cardinal; D1 : Cardinal; D2 : Cardinal; D3 : Cardinal ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_QWord_( QWords : Array of UInt64 ) : TInstruction; overload;
function Instruction_With_Declare_QWord_( Q0 : UInt64 ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}
function Instruction_With_Declare_QWord_( Q0 : UInt64; Q1 : UInt64 ) : TInstruction; overload; {$IF CompilerVersion >= 23}inline;{$IFEND}

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

{$WARNINGS OFF}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Macros~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Instruction
function Instruction_GetRIP( var Instruction : TInstruction ) : UInt64; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  if ( Instruction.next_rip < Instruction.len )  then
    begin
    {$IF CompilerVersion < 23}{$RANGECHECKS OFF}{$IFEND} // RangeCheck might cause Internal-Error C1118
    result := 0;
    {$IF CompilerVersion < 23}{$RANGECHECKS ON}{$IFEND} // RangeCheck might cause Internal-Error C1118
    Exit;
    end;

  {$IF CompilerVersion < 23}{$RANGECHECKS OFF}{$IFEND} // RangeCheck might cause Internal-Error C1118
  result := Instruction.next_rip-Instruction.len;
  {$IF CompilerVersion < 23}{$RANGECHECKS ON}{$IFEND} // RangeCheck might cause Internal-Error C1118
end;

procedure Instruction_SetRIP( var Instruction : TInstruction; Value : UInt64 ); {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  {$IF CompilerVersion < 23}{$RANGECHECKS OFF}{$IFEND} // RangeCheck might cause Internal-Error C1118
  Instruction.next_rip := Value+Instruction.len;
  {$IF CompilerVersion < 23}{$RANGECHECKS ON}{$IFEND} // RangeCheck might cause Internal-Error C1118
end;

function Instruction_IsValid( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := NOT ( Instruction.Code in [ INVALID_CODE{, Int3} ] ) AND NOT ( ( Instruction.code = Add_rm8_r8 ) AND ( Instruction.regs[ 1 ] = AL ) AND ( Instruction.mem_base_reg = RAX ) );
end;

function Instruction_IsData( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Instruction.Code in [ INVALID_CODE{, Int3}, DeclareByte, DeclareWord, DeclareDWord, DeclareQword ] ) OR ( ( Instruction.code = Add_rm8_r8 ) AND ( Instruction.regs[ 1 ] = AL ) AND ( Instruction.mem_base_reg = RAX ) );
end;

function Instruction_IsProcedureStart( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Instruction.Code in [ Push_r16, Push_r32, Push_r64 ] ) AND ( Instruction.Regs[ 0 ] in [ EBP, RBP ] );
end;

function Instruction_IsJump( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Instruction.Code = Jmp_rel16 ) OR
            ( Instruction.Code = Jmp_rel32_32 ) OR ( Instruction.Code = Jmp_rel32_64 ) OR
            ( Instruction.Code = Jmp_ptr1616 )  OR ( Instruction.Code = Jmp_ptr1632 )  OR
            ( Instruction.Code = Jmp_rel8_16 )  OR ( Instruction.Code = Jmp_rel8_32 )  OR ( Instruction.Code = Jmp_rel8_64 ) OR
            ( Instruction.Code = Jmp_rm16 )     OR ( Instruction.Code = Jmp_rm32 )     OR ( Instruction.Code = Jmp_rm64 ) OR
            ( Instruction.Code = Jmp_m1616 )    OR ( Instruction.Code = Jmp_m1632 )    OR ( Instruction.Code = Jmp_m1664 ) OR

            Instruction_IsConditionalJump( Instruction ) OR Instruction_IsCall( Instruction );
end;

function Instruction_IsRegJump( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := Instruction_IsJump( Instruction ) AND ( ( Instruction.op_kinds[ 0 ] <> okRegister_ ) OR ( Instruction.mem_displ <> 0 ) );
end;

function Instruction_IsConditionalJump( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Instruction.Code = Je_rel8_64 )  OR  ( Instruction.Code = Jp_rel8_16 )  OR ( Instruction.Code = Jg_rel8_32 ) OR ( Instruction.Code = Jle_rel16 )    OR ( Instruction.Code = Jle_rel32_32 ) OR ( Instruction.Code = Jle_rel32_64 ) OR ( Instruction.Code = Jnp_rel16 ) OR
            ( Instruction.Code = Jne_rel8_16 ) OR  ( Instruction.Code = Jp_rel8_32 )  OR ( Instruction.Code = Jg_rel8_64 ) OR ( Instruction.Code = Jg_rel16 )     OR ( Instruction.Code = Jg_rel32_32 )  OR ( Instruction.Code = Jg_rel32_64 )  OR ( Instruction.Code = Jl_rel16 )  OR
            ( Instruction.Code = Jne_rel8_32 ) OR  ( Instruction.Code = Jp_rel8_64 )  OR ( Instruction.Code = Jo_rel16 )   OR ( Instruction.Code = Jo_rel32_32 )  OR ( Instruction.Code = Jo_rel32_64 )  OR ( Instruction.Code = Jo_rel8_16 )   OR ( Instruction.Code = Jge_rel16 ) OR
            ( Instruction.Code = Jne_rel8_64 ) OR  ( Instruction.Code = Jnp_rel8_16 ) OR ( Instruction.Code = Jno_rel16 )  OR ( Instruction.Code = Jno_rel32_32 ) OR ( Instruction.Code = Jno_rel32_64 ) OR ( Instruction.Code = Jo_rel8_32 )   OR
            ( Instruction.Code = Jbe_rel8_16 ) OR  ( Instruction.Code = Jnp_rel8_32 ) OR ( Instruction.Code = Jb_rel16 )   OR ( Instruction.Code = Jb_rel32_32 )  OR ( Instruction.Code = Jb_rel32_64 )  OR ( Instruction.Code = Jo_rel8_64 )   OR
            ( Instruction.Code = Jbe_rel8_32 ) OR  ( Instruction.Code = Jnp_rel8_64 ) OR ( Instruction.Code = Jae_rel16 )  OR ( Instruction.Code = Jae_rel32_32 ) OR ( Instruction.Code = Jae_rel32_64 ) OR ( Instruction.Code = Jno_rel8_16 )  OR
            ( Instruction.Code = Jbe_rel8_64 ) OR  ( Instruction.Code = Jl_rel8_16 )  OR ( Instruction.Code = Je_rel16 )   OR ( Instruction.Code = Je_rel32_32 )  OR ( Instruction.Code = Je_rel32_64 )  OR ( Instruction.Code = Jno_rel8_32 )  OR
            ( Instruction.Code = Ja_rel8_16 )  OR  ( Instruction.Code = Jl_rel8_32 )  OR ( Instruction.Code = Jne_rel16 )  OR ( Instruction.Code = Jne_rel32_32 ) OR ( Instruction.Code = Jne_rel32_64 ) OR ( Instruction.Code = Jno_rel8_64 )  OR
            ( Instruction.Code = Ja_rel8_32 )  OR  ( Instruction.Code = Jl_rel8_64 )  OR ( Instruction.Code = Jbe_rel16 )  OR ( Instruction.Code = Jbe_rel32_32 ) OR ( Instruction.Code = Jbe_rel32_64 ) OR ( Instruction.Code = Jb_rel8_16 )   OR
            ( Instruction.Code = Ja_rel8_64 )  OR  ( Instruction.Code = Jge_rel8_16 ) OR ( Instruction.Code = Ja_rel16 )   OR ( Instruction.Code = Ja_rel32_32 )  OR ( Instruction.Code = Ja_rel32_64 )  OR ( Instruction.Code = Jb_rel8_32 )   OR
            ( Instruction.Code = Js_rel8_16 )  OR  ( Instruction.Code = Jge_rel8_32 ) OR ( Instruction.Code = Js_rel16 )   OR ( Instruction.Code = Js_rel32_32 )  OR ( Instruction.Code = Js_rel32_64 )  OR ( Instruction.Code = Jb_rel8_64 )   OR
            ( Instruction.Code = Js_rel8_32 )  OR  ( Instruction.Code = Jge_rel8_64 ) OR ( Instruction.Code = Jns_rel16 )  OR ( Instruction.Code = Jns_rel32_32 ) OR ( Instruction.Code = Jns_rel32_64 ) OR ( Instruction.Code = Jae_rel8_16 )  OR
            ( Instruction.Code = Js_rel8_64 )  OR  ( Instruction.Code = Jle_rel8_16 ) OR ( Instruction.Code = Jp_rel16 )   OR ( Instruction.Code = Jp_rel32_32 )  OR ( Instruction.Code = Jp_rel32_64 )  OR ( Instruction.Code = Jae_rel8_32 )  OR
            ( Instruction.Code = Jns_rel8_16 ) OR  ( Instruction.Code = Jle_rel8_32 ) OR ( Instruction.Code = Jnp_rel16 )  OR ( Instruction.Code = Jnp_rel32_32 ) OR ( Instruction.Code = Jnp_rel32_64 ) OR ( Instruction.Code = Jae_rel8_64 )  OR
            ( Instruction.Code = Jns_rel8_32 ) OR  ( Instruction.Code = Jle_rel8_64 ) OR ( Instruction.Code = Jl_rel16 )   OR ( Instruction.Code = Jl_rel32_32 )  OR ( Instruction.Code = Jl_rel32_64 )  OR ( Instruction.Code = Je_rel8_16 )   OR
            ( Instruction.Code = Jns_rel8_64 ) OR  ( Instruction.Code = Jg_rel8_16 )  OR ( Instruction.Code = Jge_rel16 )  OR ( Instruction.Code = Jge_rel32_32 ) OR ( Instruction.Code = Jge_rel32_64 ) OR ( Instruction.Code = Je_rel8_32 );
end;

function Instruction_IsCall( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Instruction.Code = Call_ptr1616 )  OR ( Instruction.Code = Call_ptr1632 )  OR ( Instruction.Code = Call_rel16 ) OR
            ( Instruction.Code = Call_rel32_32 ) OR ( Instruction.Code = Call_rel32_64 ) OR
            ( Instruction.Code = Call_rm16 )     OR ( Instruction.Code = Call_rm32 )     OR ( Instruction.Code = Call_rm64 ) OR
            ( Instruction.Code = Call_m1616 )    OR ( Instruction.Code = Call_m1632 )    OR ( Instruction.Code = Call_m1664 );
end;

function Instruction_IsRet( var Instruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Instruction.Code = Retnw_imm16 ) OR ( Instruction.Code = Retnd_imm16 ) OR ( Instruction.Code = Retnq_imm16 ) OR
            ( Instruction.Code = Retnw ) OR ( Instruction.Code = Retnd ) OR ( Instruction.Code = Retnq );
end;

function Instruction_IsEqual( var Instruction : TInstruction; var CompareInstruction : TInstruction ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := // ( Instruction.next_rip      = CompareInstruction.next_rip ) AND
            ( Instruction.mem_displ     = CompareInstruction.mem_displ ) AND
            ( Instruction.flags1        = CompareInstruction.flags1 ) AND
            ( Instruction.immediate     = CompareInstruction.immediate ) AND
            ( Instruction.code          = CompareInstruction.code ) AND
            ( Instruction.mem_base_reg  = CompareInstruction.mem_base_reg ) AND
            ( Instruction.mem_index_reg = CompareInstruction.mem_index_reg ) AND

            ( Instruction.regs[ 0 ] = CompareInstruction.regs[ 0 ] ) AND
            ( Instruction.regs[ 1 ] = CompareInstruction.regs[ 1 ] ) AND
            ( Instruction.regs[ 2 ] = CompareInstruction.regs[ 2 ] ) AND
            ( Instruction.regs[ 3 ] = CompareInstruction.regs[ 3 ] ) AND

            ( Instruction.op_kinds[ 0 ] = CompareInstruction.op_kinds[ 0 ] ) AND
            ( Instruction.op_kinds[ 1 ] = CompareInstruction.op_kinds[ 1 ] ) AND
            ( Instruction.op_kinds[ 2 ] = CompareInstruction.op_kinds[ 2 ] ) AND
            ( Instruction.op_kinds[ 3 ] = CompareInstruction.op_kinds[ 3 ] ) AND

            ( Instruction.scale         = CompareInstruction.scale ) AND
            ( Instruction.displ_size    = CompareInstruction.displ_size ) AND
            ( Instruction.len           = CompareInstruction.len ) AND
            ( Instruction.pad           = CompareInstruction.pad );
end;

// ConstantOffsets
function ConstantOffsets_HasDisplacement( var Offsets : TConstantOffsets ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Offsets.displacement_size <> 0 );
end;

function ConstantOffsets_HasImmediate( var Offsets : TConstantOffsets ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Offsets.immediate_size <> 0 );
end;

function ConstantOffsets_HasImmediate2( var Offsets : TConstantOffsets ) : Boolean; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result := ( Offsets.immediate_size2 <> 0 );
end;

// MemoryOperand
// # Arguments
// * `base`: Base register or [`Register::None`]
// * `index`: Index register or [`Register::None`]
// * `scale`: Index register scale (1, 2, 4, or 8)
// * `displacement`: Memory displacement
// * `displ_size`: 0 (no displ), 1 (16/32/64-bit, but use 2/4/8 if it doesn't fit in a `i8`), 2 (16-bit), 4 (32-bit) or 8 (64-bit)
// * `is_broadcast`: `true` if it's broadcast memory (EVEX instructions)
// * `segment_prefix`: Segment override or [`Register::None`]
function MemoryOperand_New( Base: TRegister; Index: TRegister; Scale: Cardinal; Displacement: Int64; DisplSize : Cardinal; IsBroadcast : Boolean; SegmentPrefix : TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := Index;
  result.Scale          := Scale;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := IsBroadcast;
  result.segment_prefix := SegmentPrefix;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `index`: Index register or [`Register::None`]
// * `scale`: Index register scale (1, 2, 4, or 8)
// * `is_broadcast`: `true` if it's broadcast memory (EVEX instructions)
// * `segment_prefix`: Segment override or [`Register::None`]
function MemoryOperand_With_Base_Index_Scale_Bcst_Seg( Base: TRegister; Index: TRegister; Scale: Cardinal; IsBroadcast : Boolean; SegmentPrefix : TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := Index;
  result.Scale          := Scale;
  result.Displacement   := 0;
  result.displ_size     := 0;
  result.is_broadcast   := IsBroadcast;
  result.segment_prefix := SegmentPrefix;
end;

// # Arguments
//
// * `base`: Base register or [`Register::None`]
// * `displacement`: Memory displacement
// * `displ_size`: 0 (no displ), 1 (16/32/64-bit, but use 2/4/8 if it doesn't fit in a `i8`), 2 (16-bit), 4 (32-bit) or 8 (64-bit)
// * `is_broadcast`: `true` if it's broadcast memory (EVEX instructions)
// * `segment_prefix`: Segment override or [`Register::None`]
function MemoryOperand_With_Base_Displ_Size_Bcst_Seg( Base: TRegister; Displacement: Int64; DisplSize : Cardinal; IsBroadcast : Boolean; SegmentPrefix : TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := None;
  result.Scale          := 1;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := IsBroadcast;
  result.segment_prefix := SegmentPrefix;
end;

// # Arguments
// * `index`: Index register or [`Register::None`]
// * `scale`: Index register scale (1, 2, 4, or 8)
// * `displacement`: Memory displacement
// * `displ_size`: 0 (no displ), 1 (16/32/64-bit, but use 2/4/8 if it doesn't fit in a `i8`), 2 (16-bit), 4 (32-bit) or 8 (64-bit)
// * `is_broadcast`: `true` if it's broadcast memory (EVEX instructions)
// * `segment_prefix`: Segment override or [`Register::None`]
function MemoryOperand_With_Index_Scale_Displ_Size_Bcst_Seg( Index: TRegister; Scale: Cardinal; Displacement: Int64; DisplSize : Cardinal; IsBroadcast : Boolean; SegmentPrefix : TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := None;
  result.Index          := Index;
  result.Scale          := Scale;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := IsBroadcast;
  result.segment_prefix := SegmentPrefix;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `displacement`: Memory displacement
// * `is_broadcast`: `true` if it's broadcast memory (EVEX instructions)
// * `segment_prefix`: Segment override or [`Register::None`]
function MemoryOperand_With_Base_Displ_Bcst_Seg( Base: TRegister; Displacement: Int64; IsBroadcast : Boolean; SegmentPrefix : TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := None;
  result.Scale          := 1;
  result.Displacement   := Displacement;
  result.displ_size     := 1;
  result.is_broadcast   := IsBroadcast;
  result.segment_prefix := SegmentPrefix;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `index`: Index register or [`Register::None`]
// * `scale`: Index register scale (1, 2, 4, or 8)
// * `displacement`: Memory displacement
// * `displ_size`: 0 (no displ), 1 (16/32/64-bit, but use 2/4/8 if it doesn't fit in a `i8`), 2 (16-bit), 4 (32-bit) or 8 (64-bit)
function MemoryOperand_With_Base_Index_Scale_DisplSize( Base: TRegister; Index: TRegister; Scale: Cardinal; Displacement: Int64; DisplSize : Cardinal ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := Index;
  result.Scale          := Scale;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `index`: Index register or [`Register::None`]
// * `scale`: Index register scale (1, 2, 4, or 8)
function MemoryOperand_With_Base_Index_Scale( Base: TRegister; Index: TRegister; Scale: Cardinal ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := Index;
  result.Scale          := Scale;
  result.Displacement   := 0;
  result.displ_size     := 0;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `index`: Index register or [`Register::None`]
function MemoryOperand_With_Base_Index( Base: TRegister; Index: TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := Index;
  result.Scale          := 1;
  result.Displacement   := 0;
  result.displ_size     := 0;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `displacement`: Memory displacement
// * `displ_size`: 0 (no displ), 1 (16/32/64-bit, but use 2/4/8 if it doesn't fit in a `i8`), 2 (16-bit), 4 (32-bit) or 8 (64-bit)
function MemoryOperand_With_Base_Displ_Size( Base: TRegister; Displacement: Int64; DisplSize : Cardinal ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := None;
  result.Scale          := 1;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `index`: Index register or [`Register::None`]
// * `scale`: Index register scale (1, 2, 4, or 8)
// * `displacement`: Memory displacement
// * `displ_size`: 0 (no displ), 1 (16/32/64-bit, but use 2/4/8 if it doesn't fit in a `i8`), 2 (16-bit), 4 (32-bit) or 8 (64-bit)
function MemoryOperand_With_Index_Scale_Displ_Size( Index: TRegister; Scale: Cardinal; Displacement: Int64; DisplSize : Cardinal ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := None;
  result.Index          := Index;
  result.Scale          := Scale;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
// * `displacement`: Memory displacement
function MemoryOperand_With_Base_Displ( Base: TRegister; Displacement: Int64 ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := None;
  result.Scale          := 1;
  result.Displacement   := Displacement;
  result.displ_size     := 1;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `base`: Base register or [`Register::None`]
function MemoryOperand_With_Base( Base: TRegister ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := Base;
  result.Index          := None;
  result.Scale          := 1;
  result.Displacement   := 0;
  result.displ_size     := 0;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

// # Arguments
// * `displacement`: Memory displacement
// * `displ_size`: 2 (16-bit), 4 (32-bit) or 8 (64-bit)
function MemoryOperand_With_Displ( Displacement: Int64; DisplSize : Cardinal ) : TMemoryOperand; {$IF CompilerVersion >= 23}inline;{$IFEND}
begin
  result.Base           := None;
  result.Index          := None;
  result.Scale          := 1;
  result.Displacement   := Displacement;
  result.displ_size     := DisplSize;
  result.is_broadcast   := False;
  result.segment_prefix := None;
end;

function ParseRFlags( RFlags : TRFlag ) : String;
begin
  result := ParseRFlags( RFlags.Value );
end;

function ParseRFlags( RFlags : Cardinal ) : String;
begin
  result := '';

  if ( ( RFlags AND rfOF ) <> 0 ) then
    result := result + ', OF';
  if ( ( RFlags AND rfSF ) <> 0 ) then
    result := result + ', SF';
  if ( ( RFlags AND rfZF ) <> 0 ) then
    result := result + ', ZF';
  if ( ( RFlags AND rfAF ) <> 0 ) then
    result := result + ', AF';
  if ( ( RFlags AND rfCF ) <> 0 ) then
    result := result + ', CF';
  if ( ( RFlags AND rfPF ) <> 0 ) then
    result := result + ', PF';
  if ( ( RFlags AND rfDF ) <> 0 ) then
    result := result + ', DF';
  if ( ( RFlags AND rfIF ) <> 0 ) then
    result := result + ', IF';
  if ( ( RFlags AND rfAC ) <> 0 ) then
    result := result + ', AC';
  if ( ( RFlags AND rfUIF ) <> 0 ) then
    result := result + ', UIF';

  if ( Result <> '' ) then
    result := Copy( Result, 3, Length( result )-2 )
  else
    result := '---';
end;

// Instruction 'WITH'
// Creates an instruction with no operands
function Instruction_With_( Code : TCode ) : TInstruction;
begin
  if NOT Instruction_With( result, Code ) then
    FillChar( result, SizeOf( result ), 0 );
end;

// Creates an instruction with 1 operand
//
// # Errors
// Fails if one of the operands is invalid (basic checks)
function Instruction_With1( Code : TCode; Register_ : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With1_Register( result, Code, Register_ ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With1( Code : TCode; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With1_i32( result, Code, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With1( Code : TCode; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With1_u32( result, Code, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With1( Code : TCode; Memory : TMemoryOperand ) : TInstruction; overload;
begin
  if NOT Instruction_With1_Memory( result, Code, Memory ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Register1 : TRegister; Register2 : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With2_Register_Register( result, Code, Register1, Register2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With2_Register_i32( result, Code, Register_, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With2_Register_u32( result, Code, Register_, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : Int64 ) : TInstruction; overload;
begin
  if NOT Instruction_With2_Register_i64( result, Code, Register_, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Register_ : TRegister; Immediate : UInt64 ) : TInstruction; overload;
begin
  if NOT Instruction_With2_Register_u64( result, Code, Register_, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Register_ : TRegister; Memory : TMemoryOperand ) : TInstruction; overload;
begin
  if NOT Instruction_With2_Register_MemoryOperand( result, Code, Register_, Memory ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Immediate : Integer; Register_ : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With2_i32_Register( result, Code, Immediate, Register_ ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Immediate : Cardinal; Register_ : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With2_u32_Register( result, Code, Immediate, Register_ ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Immediate1 : Integer; Immediate2 : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With2_i32_i32( result, Code, Immediate1, Immediate2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Immediate1 : Cardinal; Immediate2 : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With2_u32_u32( result, Code, Immediate1, Immediate2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Memory : TMemoryOperand; Register_ : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With2_MemoryOperand_Register( result, Code, Memory, Register_ ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With2_MemoryOperand_i32( result, Code, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With2( Code : TCode; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With2_MemoryOperand_u32( result, Code, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_Register_Register( result, Code, Register1, Register2, Register3 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_Register_i32( result, Code, Register1, Register2, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_Register_u32( result, Code, Register1, Register2, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_Register_MemoryOperand( result, Code, Register1, Register2, Memory ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register_ : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_i32_i32( result, Code, Register_, Immediate1, Immediate2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register_ : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_u32_u32( result, Code, Register_, Immediate1, Immediate2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Register2 : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_MemoryOperand_Register( result, Code, Register1, Memory, Register2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register1 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_MemoryOperand_i32( result, Code, Register1, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Register_ : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With3_Register_MemoryOperand_u32( result, Code, Register_, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Memory : TMemoryOperand; Register1 : TRegister; Register2 : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With3_MemoryOperand_Register_Register( result, Code, Memory, Register1, Register2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Memory : TMemoryOperand; Register_ : TRegister; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With3_MemoryOperand_Register_i32( result, Code, Memory, Register_, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With3( Code : TCode; Memory : TMemoryOperand; Register_ : TRegister; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With3_MemoryOperand_Register_u32( result, Code, Memory, Register_, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_Register_Register( result, Code, Register1, Register2, Register3, Register4 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_Register_i32( result, Code, Register1, Register2, Register3, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_Register_u32( result, Code, Register1, Register2, Register3, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_Register_MemoryOperand( result, Code, Register1, Register2, Register3, Memory ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Integer; Immediate2 : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_i32_i32( result, Code, Register1, Register2, Immediate1, Immediate2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Immediate1 : Cardinal; Immediate2 : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_u32_u32( result, Code, Register1, Register2, Immediate1, Immediate2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_MemoryOperand_Register( result, Code, Register1, Register2, Memory, Register3 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_MemoryOperand_i32( result, Code, Register1, Register2, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With4( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With4_Register_Register_MemoryOperand_u32( result, Code, Register1, Register2, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With5_Register_Register_Register_Register_i32( result, Code, Register1, Register2, Register3, Register4, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Register4 : TRegister; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With5_Register_Register_Register_Register_u32( result, Code, Register1, Register2, Register3, Register4, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With5_Register_Register_Register_MemoryOperand_i32( result, Code, Register1, Register2, Register3, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Register3 : TRegister; Memory : TMemoryOperand; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With5_Register_Register_Register_MemoryOperand_u32( result, Code, Register1, Register2, Register3, Memory, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Integer ) : TInstruction; overload;
begin
  if NOT Instruction_With5_Register_Register_MemoryOperand_Register_i32( result, Code, Register1, Register2, Memory, Register3, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With5( Code : TCode; Register1 : TRegister; Register2 : TRegister; Memory : TMemoryOperand; Register3 : TRegister; Immediate : Cardinal ) : TInstruction; overload;
begin
  if NOT Instruction_With5_Register_Register_MemoryOperand_Register_u32( result, Code, Register1, Register2, Memory, Register3, Immediate ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Branch_( Code : TCode; Target : UInt64 ) : TInstruction;
begin
  if NOT Instruction_With_Branch( result, Code, Target ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Far_Branch_( Code : TCode; Selector : Word; Offset : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Far_Branch( result, Code, Selector, Offset ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_xbegin_( Bitness : Cardinal; Target : UInt64 ) : TInstruction;
begin
  if NOT Instruction_With_xbegin( result, Bitness, Target ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_outsb_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_outsb( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_outsb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_outsb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_outsw_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_outsw( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_outsw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_outsw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_outsd_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_outsd( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_outsd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_outsd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_lodsb_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_lodsb( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_lodsb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_lodsb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_lodsw_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_lodsw( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_lodsw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_lodsw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_lodsd_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_lodsd( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_lodsd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_lodsd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_lodsq_( AddressSize: Cardinal; SegmentPrefix: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_lodsq( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_lodsq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_lodsq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_scasb_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_scasb( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_scasb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_scasb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_scasb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_scasb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_scasw_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_scasw( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_scasw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_scasw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_scasw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_scasw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_scasd_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_scasd( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_scasd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_scasd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_scasd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_scasd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_scasq_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_scasq( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_scasq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_scasq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_scasq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_scasq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_insb_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_insb( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_insb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_insb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_insw_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_insw( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_insw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_insw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_insd_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_insd( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_insd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_insd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_stosb_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_stosb( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_stosb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_stosb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_stosw_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_stosw( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_stosw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_stosw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_stosd_( AddressSize: Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_stosd( result, AddressSize, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_stosd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_stosd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_stosq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_stosq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_cmpsb_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_cmpsb( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_cmpsb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_cmpsb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_cmpsb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_cmpsb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_cmpsw_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_cmpsw( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_cmpsw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_cmpsw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_cmpsw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_cmpsw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_cmpsd_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_cmpsd( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_cmpsd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_cmpsd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_cmpsd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_cmpsd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_cmpsq_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_cmpsq( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repe_cmpsq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repe_cmpsq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Repne_cmpsq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Repne_cmpsq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_movsb_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_movsb( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_movsb_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_movsb( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_movsw_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_movsw( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_movsw_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_movsw( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_movsd_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_movsd( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_movsd_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_movsd( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_movsq_( AddressSize: Cardinal; SegmentPrefix : Cardinal; RepPrefix: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_movsq( result, AddressSize, SegmentPrefix, RepPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Rep_movsq_( AddressSize: Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Rep_movsq( result, AddressSize ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_maskmovq_( AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_maskmovq( result, AddressSize, Register1, Register2, SegmentPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_maskmovdqu_( AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_maskmovdqu( result, AddressSize, Register1, Register2, SegmentPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_vmaskmovdqu_( AddressSize: Cardinal; Register1 : TRegister; Register2 : TRegister; SegmentPrefix : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_vmaskmovdqu( result, AddressSize, Register1, Register2, SegmentPrefix ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( Bytes : Array of Byte ) : TInstruction;
begin
  case Length( Bytes ) of
    1 : begin
        if NOT Instruction_With_Declare_Byte_1( result, Bytes[ 0 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    2 : begin
        if NOT Instruction_With_Declare_Byte_2( result, Bytes[ 0 ], Bytes[ 1 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    3 : begin
        if NOT Instruction_With_Declare_Byte_3( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    4 : begin
        if NOT Instruction_With_Declare_Byte_4( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    5 : begin
        if NOT Instruction_With_Declare_Byte_5( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    6 : begin
        if NOT Instruction_With_Declare_Byte_6( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    7 : begin
        if NOT Instruction_With_Declare_Byte_7( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    8 : begin
        if NOT Instruction_With_Declare_Byte_8( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    9 : begin
        if NOT Instruction_With_Declare_Byte_9( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   10 : begin
        if NOT Instruction_With_Declare_Byte_10( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   11 : begin
        if NOT Instruction_With_Declare_Byte_11( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ], Bytes[ 10 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   12 : begin
        if NOT Instruction_With_Declare_Byte_12( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ], Bytes[ 10 ], Bytes[ 11 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   13 : begin
        if NOT Instruction_With_Declare_Byte_13( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ], Bytes[ 10 ], Bytes[ 11 ], Bytes[ 12 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   14 : begin
        if NOT Instruction_With_Declare_Byte_14( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ], Bytes[ 10 ], Bytes[ 11 ], Bytes[ 12 ], Bytes[ 13 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   15 : begin
        if NOT Instruction_With_Declare_Byte_15( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ], Bytes[ 10 ], Bytes[ 11 ], Bytes[ 12 ], Bytes[ 13 ], Bytes[ 14 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
   16 : begin
        if NOT Instruction_With_Declare_Byte_16( result, Bytes[ 0 ], Bytes[ 1 ], Bytes[ 2 ], Bytes[ 3 ], Bytes[ 4 ], Bytes[ 5 ], Bytes[ 6 ], Bytes[ 7 ], Bytes[ 8 ], Bytes[ 9 ], Bytes[ 10 ], Bytes[ 11 ], Bytes[ 12 ], Bytes[ 13 ], Bytes[ 14 ], Bytes[ 14 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
  else
    FillChar( result, SizeOf( result ), 0 );
  end;
end;

function Instruction_With_Declare_Byte_( B0 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_1( result, B0 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_2( result, B0, B1 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_3( result, B0, B1, B2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_4( result, B0, B1, B2, B3 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_5( result, B0, B1, B2, B3 , B4 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_6( result, B0, B1, B2, B3 , B4, B5 ) then
    FillChar( result, SizeOf( result ), 0 );
end;
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_7( result, B0, B1, B2, B3 , B4, B5, B6 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_8( result, B0, B1, B2, B3 , B4, B5, B6, B7 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_9( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_10( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9 ) then
    FillChar( result, SizeOf( result ), 0 );
end;
function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_11( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9, B10 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_12( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9, B10, B11 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_13( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9, B10, B11, B12 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_14( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9, B10, B11, B12, B13 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_15( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9, B10, B11, B12, B13, B14 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Byte_( B0 : Byte; B1 : Byte; B2 : Byte; B3 : Byte; B4 : Byte; B5 : Byte; B6 : Byte; B7 : Byte; B8 : Byte; B9 : Byte; B10 : Byte; B11 : Byte; B12 : Byte; B13 : Byte; B14 : Byte; B15 : Byte ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Byte_16( result, B0, B1, B2, B3 , B4, B5, B6, B7, B8, B9, B10, B11, B12, B13, B14, B15 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( Words : Array of Word ) : TInstruction;
begin
  case Length( Words ) of
    1 : begin
        if NOT Instruction_With_Declare_Word_1( result, Words[ 0 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    2 : begin
        if NOT Instruction_With_Declare_Word_2( result, Words[ 0 ], Words[ 1 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    3 : begin
        if NOT Instruction_With_Declare_Word_3( result, Words[ 0 ], Words[ 1 ], Words[ 2 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    4 : begin
        if NOT Instruction_With_Declare_Word_4( result, Words[ 0 ], Words[ 1 ], Words[ 2 ], Words[ 3 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    5 : begin
        if NOT Instruction_With_Declare_Word_5( result, Words[ 0 ], Words[ 1 ], Words[ 2 ], Words[ 3 ], Words[ 4 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    6 : begin
        if NOT Instruction_With_Declare_Word_6( result, Words[ 0 ], Words[ 1 ], Words[ 2 ], Words[ 3 ], Words[ 4 ], Words[ 5 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    7 : begin
        if NOT Instruction_With_Declare_Word_7( result, Words[ 0 ], Words[ 1 ], Words[ 2 ], Words[ 3 ], Words[ 4 ], Words[ 5 ], Words[ 6 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    8 : begin
        if NOT Instruction_With_Declare_Word_8( result, Words[ 0 ], Words[ 1 ], Words[ 2 ], Words[ 3 ], Words[ 4 ], Words[ 5 ], Words[ 6 ], Words[ 7 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
  else
    FillChar( result, SizeOf( result ), 0 );
  end;
end;

function Instruction_With_Declare_Word_( W0 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_1( result, W0 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_2( result, W0, W1 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_3( result, W0, W1, W2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_4( result, W0, W1, W2, W3 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_5( result, W0, W1, W2, W3, W4 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_6( result, W0, W1, W2, W3, W4, W5 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_7( result, W0, W1, W2, W3, W4, W5, W6 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_Word_( W0 : Word; W1 : Word; W2 : Word; W3 : Word; W4 : Word; W5 : Word; W6 : Word; W7 : Word ) : TInstruction;
begin
  if NOT Instruction_With_Declare_Word_8( result, W0, W1, W2, W3, W4, W5, W6, W7 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_DWord_( DWords : Array of Cardinal ) : TInstruction;
begin
  case Length( DWords ) of
    1 : begin
        if NOT Instruction_With_Declare_DWord_1( result, DWords[ 0 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    2 : begin
        if NOT Instruction_With_Declare_DWord_2( result, DWords[ 0 ], DWords[ 1 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    3 : begin
        if NOT Instruction_With_Declare_DWord_3( result, DWords[ 0 ], DWords[ 1 ], DWords[ 2 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    4 : begin
        if NOT Instruction_With_Declare_DWord_4( result, DWords[ 0 ], DWords[ 1 ], DWords[ 2 ], DWords[ 3 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
  else
    FillChar( result, SizeOf( result ), 0 );
  end;
end;

function Instruction_With_Declare_DWord_( D0 : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Declare_DWord_1( result, D0 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_DWord_( D0 : Cardinal; D1 : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Declare_DWord_2( result, D0, D1 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_DWord_( D0 : Cardinal; D1 : Cardinal; D2 : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Declare_DWord_3( result, D0, D1, D2 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_DWord_( D0 : Cardinal; D1 : Cardinal; D2 : Cardinal; D3 : Cardinal ) : TInstruction;
begin
  if NOT Instruction_With_Declare_DWord_4( result, D0, D1, D2, D3 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_QWord_( QWords : Array of UInt64 ) : TInstruction;
begin
  case Length( QWords ) of
    1 : begin
        if NOT Instruction_With_Declare_QWord_1( result, QWords[ 0 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
    2 : begin
        if NOT Instruction_With_Declare_QWord_2( result, QWords[ 0 ], QWords[ 1 ] ) then
          FillChar( result, SizeOf( result ), 0 );
        end;
  else
    FillChar( result, SizeOf( result ), 0 );
  end;
end;

function Instruction_With_Declare_QWord_( Q0 : UInt64 ) : TInstruction;
begin
  if NOT Instruction_With_Declare_QWord_1( result, Q0 ) then
    FillChar( result, SizeOf( result ), 0 );
end;

function Instruction_With_Declare_QWord_( Q0 : UInt64; Q1 : UInt64 ) : TInstruction;
begin
  if NOT Instruction_With_Declare_QWord_2( result, Q0, Q1 ) then
    FillChar( result, SizeOf( result ), 0 );
end;
{$WARNINGS ON}

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
