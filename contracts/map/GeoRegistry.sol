pragma solidity ^0.5.5;

import "../interfaces/IControl.sol";

contract GeoRegistry {

  // ------------------------------------------------
  //
  // Variables Private
  //
  // ------------------------------------------------

  // set once in constructor()
  //      geohashChar bitmask
  mapping(bytes1 => bytes4) private charToBitmask;
  //
  // mapping(bytes2 => bool) private validGeohashChars;

  // ------------------------------------------------
  //
  // Variables Public
  //
  // ------------------------------------------------

  IControl public control;

  // mapping for limiting the sell amount for tellers, per tier
  //      countryCode        tier    usdDailyLimit
  // mapping(bytes2 => mapping (uint => uint)) public countryTierDailyLimit;

  //      countryCode licensePriceUSD
  mapping(bytes2 => uint) public shopLicensePrice;

  //      countryCode isEnabled
  mapping(bytes2 => bool) public countryIsEnabled;
  mapping(bytes2 => bool) public countryIsFilled;

  bytes2[] public enabledCountries;

  //      countryCode       geohashFirst3 bitmaskLevel4
  mapping(bytes2 => mapping(bytes3 => bytes4)) public level_2;

  // ------------------------------------------------
  //
  // Events
  //
  // ------------------------------------------------

  event GeoRegistryCountryEnabled(bytes2 indexed country);
  event GeoRegistryCountryDisabled(bytes2 indexed country);

  // ------------------------------------------------
  //
  // Constructor
  //
  // ------------------------------------------------

  constructor(address _control)
    public
  {
    control = IControl(_control);

    // TODO: improve below code? https://medium.com/@imolfar/bitwise-operations-and-bit-manipulation-in-solidity-ethereum-1751f3d2e216
    charToBitmask[bytes1("v")] = hex"80000000"; // 2147483648
    charToBitmask[bytes1("y")] = hex"40000000"; // 1073741824
    charToBitmask[bytes1("z")] = hex"20000000"; // 536870912
    charToBitmask[bytes1("b")] = hex"10000000"; // 268435456
    charToBitmask[bytes1("c")] = hex"08000000"; // 134217728
    charToBitmask[bytes1("f")] = hex"04000000"; // 67108864
    charToBitmask[bytes1("g")] = hex"02000000"; // 33554432
    charToBitmask[bytes1("u")] = hex"01000000"; // 16777216
    charToBitmask[bytes1("t")] = hex"00800000"; // 8388608
    charToBitmask[bytes1("w")] = hex"00400000"; // 4194304
    charToBitmask[bytes1("x")] = hex"00200000"; // 2097152
    charToBitmask[bytes1("8")] = hex"00100000"; // 1048576
    charToBitmask[bytes1("9")] = hex"00080000"; // 524288
    charToBitmask[bytes1("d")] = hex"00040000"; // 262144
    charToBitmask[bytes1("e")] = hex"00020000"; // 131072
    charToBitmask[bytes1("s")] = hex"00010000"; // 65536
    charToBitmask[bytes1("m")] = hex"00008000"; // 32768
    charToBitmask[bytes1("q")] = hex"00004000"; // 16384
    charToBitmask[bytes1("r")] = hex"00002000"; // 8192
    charToBitmask[bytes1("2")] = hex"00001000"; // 4096
    charToBitmask[bytes1("3")] = hex"00000800"; // 2048
    charToBitmask[bytes1("6")] = hex"00000400"; // 1024
    charToBitmask[bytes1("7")] = hex"00000200"; // 512
    charToBitmask[bytes1("k")] = hex"00000100"; // 256
    charToBitmask[bytes1("j")] = hex"00000080"; // 128
    charToBitmask[bytes1("n")] = hex"00000040"; // 64
    charToBitmask[bytes1("p")] = hex"00000020"; // 32
    charToBitmask[bytes1("0")] = hex"00000010"; // 16
    charToBitmask[bytes1("1")] = hex"00000008"; // 8
    charToBitmask[bytes1("4")] = hex"00000004"; // 4
    charToBitmask[bytes1("5")] = hex"00000002"; // 2
    charToBitmask[bytes1("h")] = hex"00000001"; // 1
  }

  // ------------------------------------------------
  //
  // Functions Private Getters
  //
  // ------------------------------------------------

  function toBytes1(bytes memory _bytes, uint _start)
    private
    pure
    returns (bytes1)
  {
    require(_bytes.length >= (_start + 1), " not long enough");
    bytes1 tempBytes1;

    assembly {
        tempBytes1 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes1;
  }

  function toBytes3(bytes memory _bytes, uint _start)
    private
    pure
    returns (bytes3)
  {
    require(_bytes.length >= (_start + 3), " not long enough");
    bytes3 tempBytes3;

    assembly {
        tempBytes3 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes3;
  }

  // ------------------------------------------------
  //
  // Functions Public Getters
  //
  // ------------------------------------------------

  function validGeohashChars(bytes memory _bytes)
    public
    view
    returns (bool)
  {
    require(_bytes.length > 0, "_bytes geohash chars is empty array");

    for (uint i = 0; i < _bytes.length; i += 1) {
      // find the first occurence of a byte which is not valid geohash character
      if (charToBitmask[toBytes1(_bytes, i)] == bytes4(0)) {
        return false;
      }
    }
    return true;
  }
  function validGeohashChars12(bytes12 _bytes)
    public
    view
    returns (bool)
  {
    for (uint i = 0; i < 12; i += 1) {
      // find the first occurence of a byte which is not valid geohash character
      if (charToBitmask[bytes1(_bytes[i])] == bytes4(0)) {
        return false;
      }
    }
    return true;
  }

  // @NOTE: _zone can be any length of bytes
  function zoneInsideCountry(bytes2 _countryCode, bytes4 _zone)
    public
    view
    returns (bool)
  {
    bytes3 level2key = bytes3(_zone);
    bytes4 level3bits = level_2[_countryCode][level2key];

    bytes1 fourthByte = bytes1(_zone[3]);
    bytes4 fourthByteBitPosMask = charToBitmask[fourthByte];

    if (level3bits & fourthByteBitPosMask != 0) {
      return true;
    } else {
      return false;
    }
  }

  // ------------------------------------------------
  //
  // Functions Setters Public
  //
  // ------------------------------------------------

  // function setCountryTierDailyLimit(bytes2 _countryCode, uint _tier, uint _limitUsd)
  //   public
  // {
  //   // can exec while paused
  //   require(control.isCEO(msg.sender), "caller needs to be CEO");
  //   countryTierDailyLimit[_countryCode][_tier] = _limitUsd;
  // }

  function updateLevel2(bytes2 _countryCode, bytes3 _letter, bytes4 _subLetters)
    public
  {
    // can exec while paused
    // require(control.isCEO(msg.sender), "caller needs to be CEO");
    require(!countryIsFilled[_countryCode], "country must not be filled");
    level_2[_countryCode][_letter] = _subLetters;
  }
  function updateLevel2batch(bytes2 _countryCode, bytes3[] memory _letters, bytes4[] memory _subLetters)
    public
  {
    // can exec while paused
    // require(control.isCEO(msg.sender), "caller needs to be CEO");
    require(!countryIsFilled[_countryCode], "country must not be filled");
    for (uint i = 0; i < _letters.length; i++) {
      level_2[_countryCode][_letters[i]] = _subLetters[i];
    }
  }
  function endInit(bytes2 _countryCode) public
  {
    countryIsFilled[_countryCode] = true;
  }
  function enableCountry(bytes2 _country)
    external
  {
    // can exec while paused
    require(control.isCEO(msg.sender), "caller needs to be CEO");
    require(!countryIsEnabled[_country], "country already enabled");

    countryIsEnabled[_country] = true;
    enabledCountries.push(_country);

    emit GeoRegistryCountryEnabled(_country);
  }

  function disableCountry(bytes2 _country)
    external
  {
    // can exec while paused
    require(control.isCEO(msg.sender), "caller needs to be CEO");
    require(countryIsEnabled[_country], "country already disabled");

    countryIsEnabled[_country] = false;

    for (uint i = 0; i < enabledCountries.length; i++) {
      if (enabledCountries[i] == _country) {
        // replace the to-be-deleted country with the last country in the list
        enabledCountries[i] = enabledCountries[enabledCountries.length - 1];
        enabledCountries.length--;
        break;
      }
    }

    emit GeoRegistryCountryDisabled(_country);
  }
}
