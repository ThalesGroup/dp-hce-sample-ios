//
// Copyright © 2004 THALES. All rights reserved.
//

#ifndef pkcs7_util_h
#define pkcs7_util_h

typedef struct {
    long length;
    unsigned char *_Nullable value;
} DataByteArray;

DataByteArray encryptPKCS7(const unsigned char* _Nonnull pData, int dataLengt,
                           const unsigned char* _Nonnull pPublicKey, int publicKeyLength);

#endif /* pkcs7_util_h */
