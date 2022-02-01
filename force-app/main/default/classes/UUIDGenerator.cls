public with sharing class UUIDGenerator {

    public static String createId( ) {
        return EncodingUtil.convertToHex(
                Crypto.generateDigest('MD5', Blob.valueOf(DateTime.now().getTime().format() ))
        );
    }
}