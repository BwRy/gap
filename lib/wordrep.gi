#############################################################################
##
#W  wordrep.gi                  GAP library                     Thomas Breuer
#W                                                             & Frank Celler
#W                                                         & Alexander Hulpke
##
#H  @(#)$Id: wordrep.gi,v 4.51 2010/02/23 15:13:37 gap Exp $
##
#Y  Copyright (C)  1997,  Lehrstuhl D für Mathematik,  RWTH Aachen,  Germany
#Y  (C) 1998 School Math and Comp. Sci., University of St Andrews, Scotland
#Y  Copyright (C) 2002 The GAP Group
##
##  This  file contains  methods for   associative words in syllable
##  representation.
##
##  Currently,  there are four  representations for objects with the external
##  representation as list of generators  numbers and exponents (so not  only
##  for  associative  words but  perhaps  also for   elements  in a  finitely
##  presented group).
##
##  The   representations differ  w.r.t. the  space  needed   by the internal
##  representation:
##
##  the first three need 8, 16, 32 bits for each generator/exponent pair, and
##  the last  uses the list defined  by  the external representation  also as
##  internal data.
##
##  The    result of an arithmetic    operation  with  objects   of the  same
##  representation  will be also of that  representation if this is possible.
##  The  result  of  an  arithmetic   operation  with  objects  of  different
##  representations  will be the bigger  one of the two  if this is possible.
##  Otherwise `ObjByExtRep' will choose the smallest possible representation.
##  In all cases the representation of the operands is *not* changed.
##
Revision.wordrep_gi :=
    "@(#)$Id: wordrep.gi,v 4.51 2010/02/23 15:13:37 gap Exp $";


#############################################################################
##
#R  Is8BitsAssocWord( <obj> )
#R  Is16BitsAssocWord( <obj> )
#R  Is32BitsAssocWord( <obj> )
#R  IsInfBitsAssocWord( <obj> )
##

DeclareRepresentation( "Is8BitsAssocWord",
    IsSyllableAssocWordRep and IsDataObjectRep, [] );

DeclareRepresentation( "Is16BitsAssocWord",
    IsSyllableAssocWordRep and IsDataObjectRep, [] );

DeclareRepresentation( "Is32BitsAssocWord",
    IsSyllableAssocWordRep and IsDataObjectRep, [] );

DeclareRepresentation( "IsInfBitsAssocWord",
    IsSyllableAssocWordRep and IsPositionalObjectRep,[]);

#############################################################################
##
#V  AWP_PURE_TYPE
#V  AWP_NR_BITS_EXP
#V  AWP_NR_GENS
#V  AWP_NR_BITS_PAIR
#V  AWP_FUN_OBJ_BY_VECTOR
#V  AWP_FUN_ASSOC_WORD
#V  AWP_FIRST_FREE
##
##  are positions of non-defining data in the types of associative words,
##  namely
##  - the pure type of the object itself, without knowledge features,
##  - the number of bits available for each exponent,
##  - the number of generators,
##  - the number of bits available for each generator/exponent pair,
##  - the construction function to be called by `ObjByVector',
##  - the construction function to be called by `AssocWord',
##  - the first position that can be used for private purposes.
##
##  This data must be provided already in the construction of the family,
##  in order to make sure that calls of `NewType' fetch types that know
##  this data.
##


#############################################################################
##
#F  InfBits_AssocWord( <Type>, <list> )
##
BindGlobal( "InfBits_AssocWord", function( Type, list )

    local n,
          i,
          j;

    # Check that the data is admissible.
    n:= Type![ AWP_NR_GENS ];
    if Length( list ) mod 2 <> 0 then
      Error( "<list> must have even length" );
    fi;
    for i in [ 1 .. Length( list ) / 2 ] do
      j:= 2*i - 1;
      if not ( IsInt( list[j] ) and list[j] > 0 and list[j] <= n ) then
        Error( "value at odd position <j> must denote generator" );
      fi;
      if not IsInt( list[ j+1 ] ) then
        Error( "value at even position <j+1> must be an integer" );
      fi;
    od;
    return Objectify( Type, [ Immutable( list ) ] );
end );


#############################################################################
##
#M  Print( <w> )
##
InstallMethod( PrintObj, "for an associative word", true,
    [ IsAssocWord ], 0,
function( elm )

    local names,
          word,
          len,
          i;

  names:= FamilyObj( elm )!.names;
  word:= ExtRepOfObj( elm );
  len:= Length( word ) - 1;
  i:= 1;
  if len < 0 then
    Print( "<identity ...>" );
  else
    while i < len do
      Print( names[ word[i] ] );
      if word[ i+1 ] <> 1 then
	Print( "^", word[ i+1 ] );
      fi;
      Print( "*" );
      i:= i+2;
    od;
    Print( names[ word[i] ] );
    if word[ i+1 ] <> 1 then
      Print( "^", word[ i+1 ] );
    fi;
  fi;
end );


#############################################################################
##
#M  String( <w> )
##
InstallMethod( String,
    "for an associative word",
    true,
    [ IsAssocWord ], 0,
    function( elm )

    local names,
          word,
          len,
          i,
          str;

    names:= FamilyObj( elm )!.names;
    word:= ExtRepOfObj( elm );
    len:= Length( word ) - 1;
    i:= 1;
    str:= "";
    if len < 0 then
      return "<identity ...>";
#T ??
    fi;
    while i < len do
      Append( str, names[ word[i] ] );
      if word[ i+1 ] <> 1 then
        Add( str, '^' );
        Append( str, String(word[ i+1 ]) );
      fi;
      Add( str, '*' );
      i:= i+2;
    od;
    Append( str, names[ word[i] ] );
    if word[ i+1 ] <> 1 then
      Add( str, '^' );
      Append( str, String(word[ i+1 ]) );
    fi;
    ConvertToStringRep( str );
    return str;
    end );


#############################################################################
##
#F  AssocWord( <Type>, <descr> )
##
InstallGlobalFunction( AssocWord, function( Type, descr )
    return Type![ AWP_FUN_ASSOC_WORD ]( Type![ AWP_PURE_TYPE ], descr );
end );


#############################################################################
##
#M  ObjByExtRep( <F>, <descr> )
##
BindGlobal("SyllableWordObjByExtRep",function( F, descr )
local maxexp,   # maximal exponent in `descr'
      i,        # loop over exponents in `descr'
      expbits;  # list of maximal exponents for the four representations

  maxexp:= 0;
  for i in [ 2, 4 .. Length( descr ) ] do
    if maxexp < descr[i] then
      maxexp:= descr[i];
    elif maxexp < - descr[i] then
      maxexp:= - descr[i];
    fi;
  od;
  if IsInfBitsFamily(F) then
    return AssocWord( F!.types[4], descr );
  fi;

  expbits:= F!.expBitsInfo;
  if   maxexp < expbits[2] then
    if maxexp < expbits[1] then
      return AssocWord( F!.types[1], descr );
    else
      return AssocWord( F!.types[2], descr );
    fi;
  elif maxexp < expbits[3] then
      return AssocWord( F!.types[3], descr );
  else
      return AssocWord( F!.types[4], descr );
  fi;
end );

InstallMethod( ObjByExtRep,
    "for a family of associative words, and a homogeneous list", true,
    [ IsAssocWordFamily and IsSyllableWordsFamily, IsHomogeneousList ], 0,
    SyllableWordObjByExtRep);

InstallMethod(SyllableRepAssocWord, "assoc word: via extrep", true,
  [ IsAssocWord ], 0,
  w->SyllableWordObjByExtRep(FamilyObj(w),ExtRepOfObj(w)));

InstallMethod(SyllableRepAssocWord, "assoc word in syllable rep", true,
  [ IsAssocWord and IsSyllableAssocWordRep], 0, w->w);

InstallOtherMethod( ObjByExtRep,
    "for a 8Bits-family of associative words, and a homogeneous list",
    true,
    [ IsAssocWordFamily and Is8BitsFamily, IsHomogeneousList ], 0,
    function( F, descr )
    return AssocWord( F!.types[1], descr );
    end );

InstallOtherMethod( ObjByExtRep,
    "for a 16Bits-family of associative words, and a homogeneous list",
    true,
    [ IsAssocWordFamily and Is16BitsFamily, IsHomogeneousList ], 0,
    function( F, descr )
    return AssocWord( F!.types[2], descr );
    end );

InstallOtherMethod( ObjByExtRep,
    "for a 32Bits-family of associative words, and a homogeneous list",
    true,
    [ IsAssocWordFamily and Is32BitsFamily, IsHomogeneousList ], 0,
    function( F, descr )
    return AssocWord( F!.types[3], descr );
    end );

InstallOtherMethod( ObjByExtRep,
    "for a InfBits-family of associative words, and a homogeneous list",
    true,
    [ IsAssocWordFamily and IsInfBitsFamily, IsHomogeneousList ], 0,
    function( F, descr )
    return AssocWord( F!.types[4], descr );
    end );


#############################################################################
##
#M  ObjByExtRep( <F>, <expbits>, <maxcand>, <descr> )
##
##  is an object that belongs to the smallest possible type that has
##  at least <expbits> bits for the exponent and that allows <maxcand> as
##  exponent.
##
##  If the family itself knows that its objects have (at most) a specified
##  size then objects of the corresponding type are created faster.
##
InstallOtherMethod( ObjByExtRep,
    "for a fam. of assoc. words, a cyclotomic, an int., and a homog. list",
    true,
    [ IsAssocWordFamily and IsSyllableWordsFamily,
      IsCyclotomic, IsInt, IsHomogeneousList ], 0,
    function( F, exp, maxcand, descr )

    local info, expbits;

    # Choose the appropriate type.
    if maxcand < 0 then
      maxcand:= - maxcand;
    fi;
    info:= F!.expBitsInfo;
    expbits:= F!.expBits;
    if   exp <= expbits[2] and maxcand < info[2] then
      if exp <= expbits[1] and maxcand < info[1] then
        return AssocWord( F!.types[1], descr );
      else
        return AssocWord( F!.types[2], descr );
      fi;
    elif exp <= expbits[3] and maxcand < info[3] then
        return AssocWord( F!.types[3], descr );
    else
        return AssocWord( F!.types[4], descr );
    fi;
    end );


#############################################################################
##
#M  Install (internal) methods for objects of the 8 bits type
##
InstallMethod( ExtRepOfObj,
    "for an 8 bits assoc. word",
    true,
    [ Is8BitsAssocWord ], 0,
    8Bits_ExtRepOfObj );

InstallMethod( \=,
    "for two 8 bits assoc. words",
    IsIdenticalObj,
    [ Is8BitsAssocWord, Is8BitsAssocWord ], 0,
    8Bits_Equal );

InstallMethod( \<,
    "for two 8 bits assoc. words",
    IsIdenticalObj,
    [ Is8BitsAssocWord, Is8BitsAssocWord ], 0,
    8Bits_Less );

InstallMethod( \*,
    "for two 8 bits assoc. words",
    IsIdenticalObj,
    [ Is8BitsAssocWord, Is8BitsAssocWord ], 0,
    8Bits_Product );

InstallMethod( OneOp,
    "for an 8 bits assoc. word-with-one",
    true,
    [ Is8BitsAssocWord and IsAssocWordWithOne ], 0,
    x -> 8Bits_AssocWord( FamilyObj( x )!.types[1], [] ) );


InstallMethod( \^,
    "for an 8 bits assoc. word, and zero (in small integer rep)",
    true,
    [ Is8BitsAssocWord and IsMultiplicativeElementWithOne, 
      IsZeroCyc and IsSmallIntRep ], 0,
    8Bits_Power );

InstallMethod( \^,
    "for an 8 bits assoc. word, and a small negative integer",
    true,
    [ Is8BitsAssocWord and IsMultiplicativeElementWithInverse,
      IsInt and IsNegRat and IsSmallIntRep ], 0,
    8Bits_Power );

InstallMethod( \^,
    "for an 8 bits assoc. word, and a small positive integer",
    true,
    [ Is8BitsAssocWord, IsPosInt and IsSmallIntRep ], 0,
    8Bits_Power );


InstallMethod( ExponentSyllable,
    "for an 8 bits assoc. word, and a pos. integer",
    true,
    [ Is8BitsAssocWord, IsPosInt ], 0,
    8Bits_ExponentSyllable );

InstallMethod( GeneratorSyllable,
    "for an 8 bits assoc. word, and an integer",
    true,
    [ Is8BitsAssocWord, IsInt ], 0,
    8Bits_GeneratorSyllable );

InstallMethod( NumberSyllables,
    "for an 8 bits assoc. word",
    true,
    [ Is8BitsAssocWord ], 0,
    8Bits_NumberSyllables );

InstallMethod( ExponentSums,
    "for an 8 bits assoc. word",
    true,
    [ Is8BitsAssocWord ], 0,
    8Bits_ExponentSums1 );

InstallOtherMethod( ExponentSums,
    "for an 8 bits assoc. word, and two integers",
    true,
    [ Is8BitsAssocWord, IsInt, IsInt ], 0,
    8Bits_ExponentSums3 );

InstallOtherMethod( Length,
    "for an 8 bits assoc. word",
    true,
    [ Is8BitsAssocWord ], 0,
    8Bits_LengthWord );


#############################################################################
##
#M  Install (internal) methods for objects of the 16 bits type
##
InstallMethod( ExtRepOfObj,
    "for a 16 bits assoc. word",
    true,
    [ Is16BitsAssocWord ], 0,
    16Bits_ExtRepOfObj );

InstallMethod( \=,
    "for two 16 bits assoc. words",
    IsIdenticalObj,
    [ Is16BitsAssocWord, Is16BitsAssocWord ], 0,
    16Bits_Equal );

InstallMethod( \<,
    "for two 16 bits assoc. words",
    IsIdenticalObj,
    [ Is16BitsAssocWord, Is16BitsAssocWord ], 0,
    16Bits_Less );

InstallMethod( \*,
    "for two 16 bits assoc. words",
    IsIdenticalObj,
    [ Is16BitsAssocWord, Is16BitsAssocWord ], 0,
    16Bits_Product );

InstallMethod( OneOp,
    "for a 16 bits assoc. word-with-one",
    true,
    [ Is16BitsAssocWord and IsAssocWordWithOne ], 0,
    x -> 16Bits_AssocWord( FamilyObj( x )!.types[2], [] ) );


InstallMethod( \^,
    "for a 16 bits assoc. word, and zero (in small integer rep)",
    true,
    [ Is16BitsAssocWord and IsMultiplicativeElementWithOne, 
      IsZeroCyc and IsSmallIntRep ], 0,
    16Bits_Power );

InstallMethod( \^,
    "for a 16 bits assoc. word, and a small negative integer",
    true,
    [ Is16BitsAssocWord and IsMultiplicativeElementWithInverse,
      IsInt and IsNegRat and IsSmallIntRep ], 0,
    16Bits_Power );

InstallMethod( \^,
    "for a 16 bits assoc. word, and a small positive integer",
    true,
    [ Is16BitsAssocWord, IsPosInt and IsSmallIntRep ], 0,
    16Bits_Power );


InstallMethod( ExponentSyllable,
    "for a 16 bits assoc. word, and pos. integer",
    true,
    [ Is16BitsAssocWord, IsPosInt ], 0,
    16Bits_ExponentSyllable );

InstallMethod( GeneratorSyllable,
    "for a 16 bits assoc. word, and integer",
    true,
    [ Is16BitsAssocWord, IsInt ], 0,
    16Bits_GeneratorSyllable );

InstallMethod( NumberSyllables,
    "for a 16 bits assoc. word",
    true,
    [ Is16BitsAssocWord ], 0,
    16Bits_NumberSyllables );

InstallMethod( ExponentSums,
    "for a 16 bits assoc. word",
    true,
    [ Is16BitsAssocWord ], 0,
    16Bits_ExponentSums1 );

InstallOtherMethod( ExponentSums,
    "for a 16 bits assoc. word, and two integers",
    true,
    [ Is16BitsAssocWord, IsInt, IsInt ], 0,
    16Bits_ExponentSums3 );

InstallOtherMethod( Length,
    "for a 16 bits assoc. word",
    true,
    [ Is16BitsAssocWord ], 0,
    16Bits_LengthWord );


#############################################################################
##
#M  Install (internal) methods for objects of the 32 bits type
##
InstallMethod( ExtRepOfObj,
    "for a 32 bits assoc. word",
    true,
    [ Is32BitsAssocWord ], 0,
    32Bits_ExtRepOfObj );

InstallMethod( \=,
    "for two 32 bits assoc. words",
    IsIdenticalObj,
    [ Is32BitsAssocWord, Is32BitsAssocWord ], 0,
    32Bits_Equal );

InstallMethod( \<,
    "for two 32 bits assoc. words",
    IsIdenticalObj,
    [ Is32BitsAssocWord, Is32BitsAssocWord ], 0,
    32Bits_Less );

InstallMethod( \*,
    "for two 32 bits assoc. words",
    IsIdenticalObj,
    [ Is32BitsAssocWord, Is32BitsAssocWord ], 0,
    32Bits_Product );

InstallMethod( OneOp,
    "for a 32 bits assoc. word-with-one",
    true,
    [ Is32BitsAssocWord and IsAssocWordWithOne ], 0,
    x -> 32Bits_AssocWord( FamilyObj( x )!.types[3], [] ) );


InstallMethod( \^,
    "for a 32 bits assoc. word, and zero (in small integer rep)",
    true,
    [ Is32BitsAssocWord and IsMultiplicativeElementWithOne, 
      IsZeroCyc and IsSmallIntRep ], 0,
    32Bits_Power );

InstallMethod( \^,
    "for a 32 bits assoc. word, and a small negative integer",
    true,
    [ Is32BitsAssocWord and IsMultiplicativeElementWithInverse,
      IsInt and IsNegRat and IsSmallIntRep ], 0,
    32Bits_Power );

InstallMethod( \^,
    "for a 32 bits assoc. word, and a small positive integer",
    true,
    [ Is32BitsAssocWord, IsPosInt and IsSmallIntRep ], 0,
    32Bits_Power );


InstallMethod( ExponentSyllable,
    "for a 32 bits assoc. word, and pos. integer",
    true,
    [ Is32BitsAssocWord, IsPosInt ], 0,
    32Bits_ExponentSyllable );

InstallMethod( GeneratorSyllable,
    "for a 32 bits assoc. word, and pos. integer",
    true,
    [ Is32BitsAssocWord, IsPosInt ], 0,
    32Bits_GeneratorSyllable );

InstallMethod( NumberSyllables,
    "for a 32 bits assoc. word",
    true,
    [ Is32BitsAssocWord ], 0,
    32Bits_NumberSyllables );

InstallMethod( ExponentSums,
    "for a 32 bits assoc. word",
    true,
    [ Is32BitsAssocWord ], 0,
    32Bits_ExponentSums1 );

InstallOtherMethod( ExponentSums,
    "for a 32 bits assoc. word",
    true,
    [ Is32BitsAssocWord, IsInt, IsInt ], 0,
    32Bits_ExponentSums3 );

InstallOtherMethod( Length,
    "for a 32 bits assoc. word",
    true,
    [ Is32BitsAssocWord ], 0,
    32Bits_LengthWord );


#############################################################################
##
#M  Install methods for objects of the infinity type
##
InfBits_ExtRepOfObj := elm->elm![1];
InstallMethod( ExtRepOfObj,
    "for a inf. bits assoc. word",
    true,
    [ IsInfBitsAssocWord ], 0,
    InfBits_ExtRepOfObj );

InfBits_Equal := function( x, y ) return x![1] = y![1]; end;
InstallMethod( \=,
    "for two inf. bits assoc. words",
    IsIdenticalObj,
    [ IsInfBitsAssocWord, IsInfBitsAssocWord ], 0,
    InfBits_Equal );

InfBits_Less := function( u, v ) 
    local   lu, lv,      # length of u/v as a list
            len,         # difference in length of u/v as words
            i,           # loop variable  
            lexico;      # flag for the lexicoghraphic ordering of u and v

    u := u![1]; lu := Length(u);
    v := v![1]; lv := Length(v);

    ##  Discard a common prefix in u and v and decide if u is
    ##  lexicographically smaller than v.
    i := 1; while i <= lu and i <= lv and u[i] = v[i] do
        i := i+1;
    od;

    if i > lu then  ## u is a prefix of v.
        return lu < lv;
    fi;

    if i > lv then  ## v is a prefix of u, but not equal to u.
        return false;
    fi;

    ##  Decide if u is lexicographically smaller than v.
    if i mod 2 = 1 then
        ##  the generators in u and v differ
        lexico := u[i] < v[i];
        i := i+1;
    else
        ##  the exponents in u and v differ
        if u[i] = -v[i] then
            lexico := u[i] < 0;
        else
            ##  Here we have to look at the next generator in the word whose
            ##  syllable has the smaller absolute exponent in order to decide
            ##  which word is smaller.
            if AbsInt(u[i]) > AbsInt(v[i]) then
                if i+1 <= lv then
                    lexico := u[i-1] < v[i+1];
                else
                    ## Ignoring the common prefix, v is empty.
                    return false;  
                fi;
            else
                ##  |u[i]| < |v[i]|
                if i+1 <= lu then
                    lexico := u[i+1] < v[i-1];
                else
                    ## Ignoring the common prefix, u is empty.
                    return true;
                fi;
            fi;
        fi;
    fi;

    ##  Now compute the difference of the lengths
    len := 0; while i <= lu and i <= lv do
        len := len + AbsInt(u[i]);
        len := len - AbsInt(v[i]);
        i := i+2;
    od;
    ##  Only one of the following while loops will be executed.
    while i <= lu do
        len := len + AbsInt(u[i]); i := i+2;
    od;
    while i <= lv do
        len := len - AbsInt(v[i]); i := i+2;
    od;

    if len = 0 then
        return lexico;
    fi;

    return len < 0;
end;

InstallMethod( \<,
    "for two inf. bits assoc. words",
    IsIdenticalObj,
    [ IsInfBitsAssocWord, IsInfBitsAssocWord ], 100,
    InfBits_Less );

InfBits_One := x -> InfBits_AssocWord( FamilyObj(x)!.types[4],[] );
InstallMethod( OneOp,
    "for an inf. bits assoc. word-with-one",
    true,
    [ IsInfBitsAssocWord and IsAssocWordWithOne ], 0,
    InfBits_One );

InfBits_ExponentSyllable := function( x, i )
    return x![1][ 2*i ];
end;
InstallMethod( ExponentSyllable,
    "for an inf. bits assoc. word, and a pos. integer",
    true,
    [ IsInfBitsAssocWord, IsPosInt ], 0,
    InfBits_ExponentSyllable );

InfBits_GeneratorSyllable := function( x, i )
    return x![1][2*i-1];
end;
InstallMethod( GeneratorSyllable,
    "for an inf. bits assoc. word, and an integer",
    true,
    [ IsInfBitsAssocWord, IsInt ], 0,
    InfBits_GeneratorSyllable );

InfBits_NumberSyllables := x -> Length( x![1] ) / 2;
InstallMethod( NumberSyllables,
    "for an inf. bits assoc. word",
    true,
    [ IsInfBitsAssocWord ], 0,
    InfBits_NumberSyllables );

InfBits_ExponentSums1 := function( obj )
    local expvec, i;
    #expvec:= [];
    #for i in [ 1 .. TypeObj( obj )![ AWP_NR_GENS ] ] do
    #  expvec[i]:= 0;
    #od;
    expvec:=ListWithIdenticalEntries(TypeObj( obj )![ AWP_NR_GENS ],0);
    obj:= obj![1];
    for i in [ 1, 3 .. Length( obj ) - 1 ] do
      expvec[ obj[i] ]:= expvec[ obj[i] ] + obj[ i+1 ];
    od;
    return expvec;
end;
InstallMethod( ExponentSums,
    "for an inf. bits assoc. word",
    true,
    [ IsInfBitsAssocWord ], 0,
    InfBits_ExponentSums1 );


InfBits_ExponentSums3 := function( obj, from, to )
    local expvec, i;

    expvec:=ListWithIdenticalEntries(TypeObj( obj )![ AWP_NR_GENS ],0);

    # the syllable representation is a sparse representation
    obj:= obj![1];
    for i in [ 1, 3.. Length(obj)-1 ] do
        if obj[i] in [from..to] then
            expvec[ obj[i] ]:= expvec[ obj[i] ] + obj[ i+1 ];
        fi;
    od;
    return expvec;
end;
InstallOtherMethod( ExponentSums,
    "for an inf. bits assoc. word, and two integers",
    true,
    [ IsInfBitsAssocWord, IsInt, IsInt ], 1,
    InfBits_ExponentSums3 );

#############################################################################
##
#F  ObjByVector( <Type>, <vector> )
#T  ObjByVector( <Fam>, <vector> )
##
InstallGlobalFunction( ObjByVector, function( Type, vec )
    return Type![ AWP_FUN_OBJ_BY_VECTOR ]( Type![ AWP_PURE_TYPE ], vec );
end );


BindGlobal( "InfBits_ObjByVector", function( type, vec )
    local expr, i;
    expr:= [];
    for i in [ 1 .. Length( vec ) ] do
      if vec[i] <> 0 then
        Add( expr, i );
        Add( expr, vec[i] );
      fi;
    od;
    return ObjByExtRep( FamilyType(type), expr );
end );


#############################################################################
##
#M  ObjByExtRep( <Fam>, <exp>, <maxcand>, <descr> )
##
##  If the family does already know that all only words in a prescribed
##  type will be constructed then we store this in the family,
##  and `ObjByExtRep' will construct only such objects.
##
InstallOtherMethod( ObjByExtRep,
    "for an 8 bits assoc. words family, two integers, and a list",
    true,
    [ IsAssocWordFamily and Is8BitsFamily, IsInt, IsInt,
      IsHomogeneousList ], 0,
    function( F, exp, maxcand, descr )
    return 8Bits_AssocWord( F!.types[1], descr );
    end );

InstallOtherMethod( ObjByExtRep,
    "for a 16 bits assoc. words family, two integers, and a list",
    true,
    [ IsAssocWordFamily and Is16BitsFamily, IsInt, IsInt,
      IsHomogeneousList ], 0,
    function( F, exp, maxcand, descr )
    return 16Bits_AssocWord( F!.types[2], descr );
    end );

InstallOtherMethod( ObjByExtRep,
    "for a 32 bits assoc. words family, two integers, and a list",
    true,
    [ IsAssocWordFamily and Is32BitsFamily, IsInt, IsInt,
      IsHomogeneousList ], 0,
    function( F, exp, maxcand, descr )
    return 32Bits_AssocWord( F!.types[3], descr );
    end );

InstallOtherMethod( ObjByExtRep,
    "for an inf. bits assoc. words family, two integers, and a list",
    true,
    [ IsAssocWordFamily and IsInfBitsFamily, IsCyclotomic, IsInt,
      IsHomogeneousList ], 0,
    function( F, exp, maxcand, descr )
    return InfBits_AssocWord( F!.types[4], descr );
    end );


#############################################################################
##
#F  StoreInfoFreeMagma( <F>, <names>, <req> )
##
##  does the administrative work in the construction of free semigroups,
##  free monoids, and free groups.
##
##  <F> is the family of objects, <names> is a list of generators names,
##  and <req> is the required category for the elements, that is,
##  `IsAssocWord', `IsAssocWordWithOne', or `IsAssocWordWithInverse'.
##
InstallGlobalFunction( StoreInfoFreeMagma, function( F, names, req )

    local rank,
          rbits,
          K;

  # Store the names, initialize the types list.
  F!.types := [];
  F!.names := Immutable( names );

  # for letter word families we do not need these types
  if not IsFinite( names ) then

    SetFilterObj( F, IsInfBitsFamily );

  else

    # Install the data (number of bits available for exponents).
    # Note that in the case of the 32 bits representation,
    # at most 28 bits are allowed for the exponents in order to avoid
    # overflow checks.
    rank  := Length( names );
    rbits := 1;
    while 2^rbits < rank do
      rbits:= rbits + 1;
    od;
    F!.expBits:= [  8 - rbits,
		    16 - rbits,
		    Minimum( 32 - rbits, 28 ),
		    infinity ];

    # Note that one bit of the exponents is needed for the sign,
    # and we disallow the use of a representation if at most two
    # additional bits would be available.
    if F!.expBits[1] <= 3 then F!.expBits[1]:= 0; fi;
    if F!.expBits[2] <= 3 then F!.expBits[2]:= 0; fi;
    if F!.expBits[3] <= 3 then F!.expBits[3]:= 0; fi;

    F!.expBitsInfo := [ 2^( F!.expBits[1] - 1 ),
			2^( F!.expBits[2] - 1 ),
			2^( F!.expBits[3] - 1 ),
			infinity          ];

    # Store the internal types.
    NEW_TYPE_READONLY.onCreation := false;

    K:= NewType( F, Is8BitsAssocWord and req );
    K![ AWP_PURE_TYPE    ]      := K;
    K![ AWP_NR_BITS_EXP  ]      := F!.expBits[1];
    K![ AWP_NR_GENS      ]      := rank;
    K![ AWP_NR_BITS_PAIR ]      := 8;
    K![ AWP_FUN_OBJ_BY_VECTOR ] := 8Bits_ObjByVector;
    K![ AWP_FUN_ASSOC_WORD    ] := 8Bits_AssocWord;
    F!.types[1]:= K;
    MakeReadOnlyObj(K);

    K:= NewType( F, Is16BitsAssocWord and req );
    K![ AWP_PURE_TYPE    ]      := K;
    K![ AWP_NR_BITS_EXP  ]      := F!.expBits[2];
    K![ AWP_NR_GENS      ]      := rank;
    K![ AWP_NR_BITS_PAIR ]      := 16;
    K![ AWP_FUN_OBJ_BY_VECTOR ] := 16Bits_ObjByVector;
    K![ AWP_FUN_ASSOC_WORD    ] := 16Bits_AssocWord;
    F!.types[2]:= K;
    MakeReadOnlyObj(K);

    K:= NewType( F, Is32BitsAssocWord and req );
    K![ AWP_PURE_TYPE    ]      := K;
    K![ AWP_NR_BITS_EXP  ]      := F!.expBits[3];
    K![ AWP_NR_GENS      ]      := rank;
    K![ AWP_NR_BITS_PAIR ]      := 32;
    K![ AWP_FUN_OBJ_BY_VECTOR ] := 32Bits_ObjByVector;
    K![ AWP_FUN_ASSOC_WORD    ] := 32Bits_AssocWord;
    F!.types[3]:= K;
    MakeReadOnlyObj(K);

    NEW_TYPE_READONLY.onCreation := true;

  fi;

  NEW_TYPE_READONLY.onCreation := false;

  K:= NewType( F, IsInfBitsAssocWord and req );
  K![ AWP_PURE_TYPE    ]      := K;
  K![ AWP_NR_BITS_EXP  ]      := infinity;
  K![ AWP_NR_GENS      ]      := Length( names );
  K![ AWP_NR_BITS_PAIR ]      := infinity;
  K![ AWP_FUN_OBJ_BY_VECTOR ] := InfBits_ObjByVector;
  K![ AWP_FUN_ASSOC_WORD    ] := InfBits_AssocWord;
  F!.types[4]:= K;
  MakeReadOnlyObj(K);

  NEW_TYPE_READONLY.onCreation := true;

  if IsBLetterWordsFamily(F) then
    K:= NewType( F, IsBLetterAssocWordRep and req );
  else
    K:= NewType( F, IsWLetterAssocWordRep and req );
  fi;
  F!.letterWordType:=K;

end );


#############################################################################
##
#R  IsInfiniteListOfNamesRep( <list> )
##
##  is a representation of a list <list> containing at position $i$
##  either the string `<string>$i$' or the string `<init>[$i$]',
##  where the latter holds if and only if $i$ does not exceed the
##  length of the list <init>.
##
##  <string> is stored at position 1 in the positional object <list>,
##  <init> is stored at position 2.
##
DeclareRepresentation( "IsInfiniteListOfNamesRep",
    IsPositionalObjectRep,
    [ 1, 2 ] );

InstallMethod( PrintObj,
    "for an infinite list of names",
    true,
    [ IsList and IsInfiniteListOfNamesRep ], 0,
    function( list )
    Print( "InfiniteListOfNames( \"", list![1], "\", ", list![2], " )" );
    end );

InstallMethod( ViewObj,
    "for an infinite list of names",
    true,
    [ IsList and IsInfiniteListOfNamesRep ], 0,
    function( list )
    Print( "[ ", list[1], ", ", list[2], ", ... ]" );
    end );

InstallMethod( \[\],
    "for an infinite list of names",
    true,
    [ IsList and IsInfiniteListOfNamesRep, IsPosInt ], 0,
    function( list, pos )
    local entry;
    if pos <= Length( list![2] ) then
      entry:= list![2][ pos ];
    else
      entry:= Concatenation( list![1], String( pos ) );
      ConvertToStringRep( entry );
    fi;
    return entry;
    end );

InstallMethod( Length,
    "for an infinite list of names",
    true,
    [ IsList and IsInfiniteListOfNamesRep ], 0,
    list -> infinity );

InstallMethod( Position,
    "for an infinite list of names, an object, and zero",
    true,
    [ IsList and IsInfiniteListOfNamesRep, IsObject, IsZeroCyc ], 0,
    function( list, obj, zero )
    local digits, pos, i;

    # Check whether `obj' is in the initial segment, and if not,
    # whether `obj' matches the names in the rest of the list..
    pos:= Position( list![2], obj );
    if pos <> fail then
      return pos;
    elif  ( not IsString( obj ) )
       or Length( obj ) <= Length( list![1] )
       or obj{ [ 1 .. Length( list![1] ) ] } <> list![1] then
      return fail;
    fi;

    # Convert the suffix to a number if possible.
    digits:= "0123456789";
    pos:= 0;
    for i in [ Length( list![1] ) + 1 .. Length( obj ) ] do
      if obj[i] in digits then
        pos:= 10*pos + Position( digits, obj[i], 0 ) - 1;
      else
        return fail;
      fi;
    od;

    # If the number belongs to a position in the initial segment,
    # `obj' is not in the list.
    if pos <= Length( list![2] ) then
      pos:= fail;
    fi;
    return pos;
    end );


#############################################################################
##
#F  InfiniteListOfNames( <string> )
#F  InfiniteListOfNames( <string>, <init> )
##
InstallGlobalFunction( InfiniteListOfNames, function( arg )
    local string, init, list;

    if Length( arg ) = 1 and IsString( arg[1] ) then
      string := Immutable( arg[1] );
      init   := Immutable( [] );
    elif Length( arg ) = 2 and IsString( arg[1] ) and IsList( arg[2] ) then
      string := Immutable( arg[1] );
      init   := Immutable( arg[2] );
    else
      Error( "usage: InfiniteListOfNames( <string>[, <init>] )" );
    fi;

    list:= Objectify( NewType( CollectionsFamily( FamilyObj( string ) ),
                                   IsList
                               and IsDenseList
                               and IsConstantTimeAccessList
                               and IsInfiniteListOfNamesRep ),
                      [ string, init ] );
    SetIsFinite( list, false );
    SetIsEmpty( list, false );
    SetLength( list, infinity );
#T meaningless since not attribute storing!
    return list;
end );


#############################################################################
##
#R  IsInfiniteListOfGeneratorsRep( <Fam> )
##
##  is a representation used for lists containing at position $i$ the $i$-th
##  generator of the ``free something family'' <Fam>.
##  Note that we have to distinguish the cases of associative words and
##  nonassociative words, since they have different external representations.
##
##  The family <Fam> is stored at position 1 in the list object,
##  at position 2 a (possibly empty) list of initial generators is stored.
##
DeclareRepresentation( "IsInfiniteListOfGeneratorsRep",
    IsPositionalObjectRep,
    [ 1, 2 ] );

InstallMethod( ViewObj,
    "for an infinite list of generators",
    true,
    [ IsList and IsInfiniteListOfGeneratorsRep ], 0,
    function( list )
    Print( "[ ", list[1], ", ", list[2], ", ... ]" );
    end );

InstallMethod( PrintObj,
    "for an infinite list of generators",
    true,
    [ IsList and IsInfiniteListOfGeneratorsRep ], 0,
    function( list )
    Print( "[ ", list[1], ", ", list[2], ", ... ]" );
    end );

InstallMethod( Length,
    "for an infinite list of generators",
    true,
    [ IsList and IsInfiniteListOfGeneratorsRep ], 0,
    list -> infinity );

InstallMethod( \[\],
    "for an infinite list of generators",
    true,
    [ IsList and IsInfiniteListOfGeneratorsRep, IsPosInt ], 0,
    function( list, i )
    if i <= Length( list![2] ) then
      return list![2][i];
    elif IsAssocWordFamily( list![1] ) then
      if IsLetterWordsFamily(list![1]) then
	return AssocWordByLetterRep( list![1], [ i ] );
      else
	return ObjByExtRep( list![1], [ i, 1 ] );
      fi;
    else
      return ObjByExtRep( list![1], i );
    fi;
    end );

InstallMethod( Position,
    "for an infinite list of generators, an object, and zero",
    true,
    [ IsList and IsInfiniteListOfGeneratorsRep, IsObject, IsZeroCyc ], 0,
    function( list, obj, zero )
    local ext;

    if FamilyObj( obj ) <> list![1] then
      return fail;
    fi;


    if IsAssocWord( obj ) then
      ext:=LetterRepAssocWord(obj);
      if Length(ext)<> 1 or ext[1]<0 then
        return fail;
      else
        return ext[1];
      fi;
    else
      ext:= ExtRepOfObj( obj );
      if not IsInt( ext ) then
        return fail;
      else
        return ext;
      fi;
    fi;
    end );


#############################################################################
##
#M  Random( <list> )  . . . . . . . . . .  for an infinite list of generators
##
InstallMethod( Random,
    "for an infinite list of generators",
    true,
    [ IsList and IsInfiniteListOfGeneratorsRep ], 0,
    function( list )
    local pos;
    pos:= Random( Integers );
    if 0 <= pos then
      return list[ 2 * pos + 1 ];
    else
      return list[ -2 * pos ];
    fi;
    end );
#T should be moved to list.gi, or?


#############################################################################
##
#F  InfiniteListOfGenerators( <F> )
#F  InfiniteListOfGenerators( <F>, <init> )
##
InstallGlobalFunction( InfiniteListOfGenerators, function( arg )
    local F, init, list;
    if Length( arg ) = 1 and IsFamily( arg[1] ) then
      F    := arg[1];
      init := Immutable( [] );
    elif Length( arg ) = 2 and IsFamily( arg[1] ) and IsList( arg[2] ) then
      F    := arg[1];
      init := Immutable( arg[2] );
    fi;

    list:= Objectify( NewType( CollectionsFamily( F ),
                                   IsList
                               and IsDenseList
                               and IsConstantTimeAccessList
                               and IsInfiniteListOfGeneratorsRep ),
                      [ F, init ] );
    SetIsFinite( list, false );
    SetIsEmpty( list, false );
    SetLength( list, infinity );
#T meaningless since not attribute storing!
    return list;
end );

# letter representation

InstallOtherMethod(LetterRepAssocWord,"syllable rep, generators",
true, #TODO: This should be IsElmsColls once the tietze code is fixed.
  [IsSyllableAssocWordRep,IsList],0,
function ( word, generators )
local ind,n,i,e,l,g;

  ind:=[];
  n:=1;
  for i in generators do
    ind[GeneratorSyllable(i,1)]:=n;
    n:=n+1;
  od;

  e:=ExtRepOfObj(word);
  l:=[];
  for i in [1,3..Length(e)-1] do
    g:=ind[e[i]];
    n:=e[i+1];
    if n<0 then
      g:=-g;
      n:=-n;
    fi;
    Append(l,ListWithIdenticalEntries(n,g));
  od;
  return l;

end );

InstallMethod(LetterRepAssocWord,"syllable rep",true,
  [IsSyllableAssocWordRep],0,
function(word)
local n,i,e,l,g;

  e:=ExtRepOfObj(word);
  l:=[];
  for i in [1,3..Length(e)-1] do
    g:=e[i];
    n:=e[i+1];
    if n<0 then
      g:=-g;
      n:=-n;
    fi;
    Append(l,ListWithIdenticalEntries(n,g));
  od;
  return l;

end );

InstallMethod(AssocWordByLetterRep,"family, list: syllables",true,
  [IsSyllableWordsFamily,IsHomogeneousList],0,
function ( wfam,word )
local e,lg,i,num,mex;

   # first generate an external representation
   e:=[];
   mex:=1;
   lg:=0;
   i:=0;
   for num in word do
     if num<0 then
       if -num=lg then
	 # increase exponent
         e[i]:=e[i]-1;
	 mex:=Maximum(mex,-e[i]);
       else
	 # add new generator/exponent pair
         Append(e,[-num,-1]);
	 lg:=-num;
	 i:=i+2;
       fi;
     else
       if num=lg then
	 # increase exponent
         e[i]:=e[i]+1;
	 mex:=Maximum(mex,e[i]);
       else
	 # add new generator/exponent pair
         Append(e,[num,1]);
	 lg:=num;
	 i:=i+2;
       fi;
     fi;
   od;
   # then build a word from it
   e:=ObjByExtRep(wfam,mex,mex,e);
   return e;
end );


InstallOtherMethod(AssocWordByLetterRep,"family, list, gens: syllables",true,
  [IsSyllableWordsFamily,IsHomogeneousList,IsHomogeneousList],0,
function (fam, word, fgens )
local ind,e,lg,i,num,mex;

   # index the generators
   ind:=List(fgens,i->GeneratorSyllable(i,1));

   # first generate an external representation
   e:=[];
   mex:=1;
   lg:=0;
   i:=0;
   for num in word do
     if num<0 then
       if -num=lg then
	 # increase exponent
         e[i]:=e[i]-1;
	 mex:=Maximum(mex,-e[i]);
       else
	 # add new generator/exponent pair
         Append(e,[ind[-num],-1]);
	 lg:=-num;
	 i:=i+2;
       fi;
     else
       if num=lg then
	 # increase exponent
         e[i]:=e[i]+1;
	 mex:=Maximum(mex,e[i]);
       else
	 # add new generator/exponent pair
         Append(e,[ind[num],1]);
	 lg:=num;
	 i:=i+2;
       fi;
     fi;
   od;
   # then build a word from it
   e:=ObjByExtRep(fam,mex,mex,e);
   return e;
end );

#############################################################################
##
#M  Length( <w> )
##
InstallOtherMethod( Length, "for an assoc. word in syllable rep", true,
    [ IsAssocWord  and IsSyllableAssocWordRep], 0,
function( w )
local len, i;
  w:= ExtRepOfObj( w );
  len:= 0;
  for i in [ 2, 4 .. Length( w ) ] do
    len:= len + AbsInt( w[i] );
  od;
  return len;
end );


#############################################################################
##
#M  ExponentSyllable( <w>, <n> )
##
InstallMethod( ExponentSyllable,
    "for an assoc. word in syllable rep, and a positive integer", true,
    [ IsAssocWord and IsSyllableAssocWordRep, IsPosInt ], 0,
function( w, n )
  return ExtRepOfObj( w )[ 2*n ];
end );


#############################################################################
##
#M  GeneratorSyllable( <w>, <n> )
##
InstallMethod( GeneratorSyllable,
    "for an assoc. word in syllable rep, and a positive integer", true,
    [ IsAssocWord and IsSyllableAssocWordRep, IsPosInt ], 0,
function( w, n )
  return ExtRepOfObj( w )[ 2*n-1 ];
end );


#############################################################################
##
#M  NumberSyllables( <w> )
##
InstallMethod( NumberSyllables, "for an assoc. word in syllable rep", true,
    [ IsAssocWord  and IsSyllableAssocWordRep], 0,
    w -> Length( ExtRepOfObj( w ) ) / 2 );


#############################################################################
##
#M  ExponentSumWord( <w>, <gen> )
##
InstallMethod( ExponentSumWord, "syllable rep as.word, gen", IsIdenticalObj,
    [ IsAssocWord and IsSyllableAssocWordRep, IsAssocWord ], 0,
function( w, gen )
local n, g, i;
  w:= ExtRepOfObj( w );
  gen:= ExtRepOfObj( gen );
  if Length( gen ) <> 2 or ( gen[2] <> 1 and gen[2] <> -1 ) then
    Error( "<gen> must be a generator" );
  fi;
  n:= 0;
  g:= gen[1];
  for i in [ 1, 3 .. Length( w ) - 1 ] do
    if w[i] = g then
      n:= n + w[ i+1 ];
    fi;
  od;
  if gen[2] = -1 then
    n:= -n;
  fi;
  return n;
end );


#############################################################################
##
#M  ExponentSums( <f>,<w> )
##
InstallOtherMethod( ExponentSums,
    "for a group and an assoc. word in syllable rep", true,
    [ IsGroup, IsAssocWord ], 0,
function( f, w )
local l,gens,g,i,p;
  
  Info(InfoWarning,2,"obsolete undocumented method");
  gens:=List(FreeGeneratorsOfFpGroup(f),x->ExtRepOfObj(x));
  g:=gens{[1..Length(gens)]}[1];
  l:=List(gens,x->0);
  w:= ExtRepOfObj( w );
  for i in [ 1, 3 .. Length( w ) - 1 ] do
    p:=Position(g,w[i]);
    l[p]:=l[p]+w[i+1];
  od;

  for i in [1..Length(l)] do
    if gens[i][2]=-1 then l[i]:=-l[i];fi;
  od;

  return l;

end );


#############################################################################
##
#E
##
