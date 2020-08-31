package main

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/subtle"
	"encoding/binary"
	"errors"
	"io/ioutil"
)

//Copied from https://github.com/NickBall/go-aes-key-wrap
//Unwrap decrypts the provided cipher text with the given AES cipher (and corresponding key), using the AES Key Wrap algorithm (RFC-3394).
//The decrypted cipher text is verified using the default IV and will return an error if validation fails.
func Unwrap(block cipher.Block, cipherText, iv []byte) ([]byte, error) {
	//Initialize variables
	a := make([]byte, 8)
	n := (len(cipherText) / 8) - 1

	r := make([][]byte, n)
	for i := range r {
		r[i] = make([]byte, 8)
		copy(r[i], cipherText[(i+1)*8:])
	}
	copy(a, cipherText[:8])

	//Compute intermediate values
	for j := 5; j >= 0; j-- {
		for i := n; i >= 1; i-- {
			t := (n * j) + i
			tBytes := make([]byte, 8)
			binary.BigEndian.PutUint64(tBytes, uint64(t))

			b := arrConcat(arrXor(a, tBytes), r[i-1])
			block.Decrypt(b, b)

			copy(a, b[:len(b)/2])
			copy(r[i-1], b[len(b)/2:])
		}
	}

	if subtle.ConstantTimeCompare(a, iv) != 1 {
		return nil, errors.New("integrity check failed - unexpected IV")
	}

	//Output
	c := arrConcat(r...)
	return c, nil
}

func arrConcat(arrays ...[]byte) []byte {
	out := make([]byte, len(arrays[0]))
	copy(out, arrays[0])
	for _, array := range arrays[1:] {
		out = append(out, array...)
	}

	return out
}

func arrXor(arrL []byte, arrR []byte) []byte {
	out := make([]byte, len(arrL))
	for x := range arrL {
		out[x] = arrL[x] ^ arrR[x]
	}
	return out
}

func a85decode(encoded []byte) []byte {
	var total uint32 = 0
	var count uint32 = 0
	result := make([]byte, 0)
	a := make([]byte, 4)
	for _, c := range encoded {
		if c == 'z' {
			result = append(result, 0, 0, 0, 0)
			continue
		}
		total = total*85 + uint32(c-33)
		count++
		if count == 5 {
			binary.BigEndian.PutUint32(a, total)
			result = append(result, a...)
			total = 0
			count = 0
		}
	}
	if count > 0 {
		padLength := 5 - count
		for count < 5 {
			count++
			total = 85*total + ('u' - 33)
		}
		binary.BigEndian.PutUint32(a, total)
		result = append(result, a[:4-padLength]...)
	}
	return result
}

func main() {
	encoded, err := ioutil.ReadFile("payload_layer5.txt")
	if err != nil {
		panic(err)
	}
	encoded = bytes.ReplaceAll(encoded, []byte("\n"), []byte(""))
	encoded = encoded[2 : len(encoded)-2]
	decoded := a85decode(encoded)
	kek := decoded[:32]
	iv := decoded[32:40]
	wrapped := decoded[40:80]
	kekcipher, err := aes.NewCipher(kek)
	key, err := Unwrap(kekcipher, wrapped, iv)
	if err != nil {
		panic(err)
	}
	iv = decoded[80:96]
	ciphertext := decoded[96:]
	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err)
	}
	plaintext := make([]byte, len(ciphertext))
	stream := cipher.NewCTR(block, iv)
	stream.XORKeyStream(plaintext, ciphertext)
	err = ioutil.WriteFile("layer6.txt", plaintext, 0644)
	if err != nil {
		panic(err)
	}
}
