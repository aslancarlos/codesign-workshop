# =============================================================================
#  codesign-workshop.sh - Machine Identity: Code Signing Workshop (PKCS#11 -> cloud HSM)
#  -----------------------------------------------------------------------------
#  Bilíngue PT/ES (DEMO_LANG=pt|es). Mostra, ao vivo:
#    - O problema de negócio e a arquitetura (chave fica no HSM)
#    - Separação de funções (owner x authorized signer)
#    - Assinatura REAL e verificável (JAR via jarsigner; CMS via openssl)
#    - Prova de que a chave privada NÃO sai do HSM (não-extraível)
#    - Governança / não-repúdio (inventário central via API + auditoria)
#    - Recap de valor + mapa de compliance
# =============================================================================

set -o pipefail

