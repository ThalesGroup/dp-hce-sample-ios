//
// Copyright © 2004 THALES. All rights reserved.
//

#include "pkcs7_util.h"
#include <openssl/cms.h>
#include <openssl/err.h>

#define PASS_IF_TRUE(__FUNC__, __VAL__) if (__VAL__) { __FUNC__(__VAL__); }

//Create x509 stack from public key
static X509* createCertificateStack(const unsigned char * publicKeyDer, int publicKeyLength) {
    BIO *pBio = BIO_new(BIO_s_mem());
    BIO_write(pBio, publicKeyDer, publicKeyLength);
    EVP_PKEY *pRSAKey = d2i_PUBKEY_bio(pBio, NULL);
    BIO_free(pBio);
    
    if (!pRSAKey) {
        return NULL;
    }
    
    X509 *pRetValue = X509_new();
    ASN1_INTEGER_set(X509_get_serialNumber(pRetValue), 1);
    X509_set_pubkey(pRetValue, pRSAKey);
    EVP_PKEY_free(pRSAKey);
    
    return pRetValue;
}

//encrypt data
DataByteArray encryptPKCS7(const unsigned char* pData, int dataLengt,
                           const unsigned char* pPublicKey, int publicKeyLength) {
    DataByteArray retValue = {.length = 0, .value = NULL};
    BIO *pBioIn = NULL, *pBioOut = NULL;
    
    
    // Registers the error strings for all libcrypto functions
    ERR_load_crypto_strings();
    
    // Try to load certificate stuck for given key.
    X509 *pCertStack = createCertificateStack(pPublicKey, publicKeyLength);
    if (!pCertStack) {
        return retValue;
    }
    
    STACK_OF(X509) *pRecips = sk_X509_new_null();
    if (pRecips && sk_X509_push(pRecips, pCertStack)) {
        pBioIn = BIO_new(BIO_s_mem());
        if (pBioIn && BIO_write(pBioIn, pData, dataLengt)) {
            CMS_ContentInfo *pCms = CMS_encrypt(pRecips, pBioIn, EVP_aes_256_cbc(), CMS_BINARY);
            if (pCms) {
                pBioOut = BIO_new(BIO_s_mem());
                if (pBioOut && i2d_CMS_bio_stream(pBioOut, pCms, pBioIn, CMS_BINARY)) {
                    unsigned char *pTempOut = NULL;
                    retValue.length = BIO_get_mem_data(pBioOut, &pTempOut);
                    // Make a copy of tempOut as it will be wiped once outBio frees
                    if (retValue.length && pTempOut) {
                        retValue.value = malloc(sizeof(unsigned char) * retValue.length);
                        memcpy(retValue.value, pTempOut, retValue.length);
                    }
                }
                
                CMS_ContentInfo_free(pCms);
            }
        }
    }
    
    PASS_IF_TRUE(BIO_free, pBioIn)
    PASS_IF_TRUE(BIO_free, pBioOut) // This will also release pTempOut. No need of manual free of that memory
    
    // If we have recips, then pop free will also release the certificate stack.
    if (pRecips) {
        sk_X509_pop_free(pRecips, X509_free);
    } else {
        X509_free(pCertStack);
    }
    
    return retValue;
}
