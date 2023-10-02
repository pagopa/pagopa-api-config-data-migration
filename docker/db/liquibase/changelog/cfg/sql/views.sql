CREATE FORCE EDITIONABLE VIEW "${schema}"."ELENCO_SERVIZI_VIEW" ("OBJ_ID", "PSP_ID", "PSP_RAG_SOC", "PSP_FLAG_STORNO", "PSP_FLAG_BOLLO", "LOGO_PSP", "FLUSSO_ID", "INTM_ID", "CANALE_ID", "NOME_SERVIZIO", "CANALE_MOD_PAG", "TIPO_VERS_COD", "CODICE_LINGUA", "INF_COND_EC_MAX", "INF_DESC_SERV", "INF_DISP_SERV", "INF_URL_CANALE", "TIMESTAMP_INS", "DATA_VALIDITA", "IMPORTO_MINIMO", "IMPORTO_MASSIMO", "COSTO_FISSO", "TAGS", "LOGO_SERVIZIO", "CANALE_APP", "ON_US", "CARRELLO_CARTE", "CODICE_ABI", "CODICE_MYBANK", "CODICE_CONVENZIONE", "FLAG_IO") AS
  WITH cte
            AS (
            SELECT
            P.ID_PSP ID_PSP,
            P.OBJ_ID OBJ_ID,
            P.RAGIONE_SOCIALE PSP_RAG_SOC,
            P.ABI ABI,
            MAX(M.OBJ_ID) ID_CDI_MASTER,
            P.CODICE_MYBANK CODICE_MYBANK
            FROM ${schema}.CDI_MASTER M, ${schema}.PSP P
            WHERE M.FK_PSP=P.OBJ_ID
            AND P.ENABLED = 'Y'
            AND M.DATA_INIZIO_VALIDITA < TRUNC(SYSDATE + 1)
            AND P.ENABLED = 'Y'
            GROUP BY P.ID_PSP, P.OBJ_ID, P.RAGIONE_SOCIALE, P.ABI, P.CODICE_MYBANK
            )
            SELECT
            ROW_NUMBER() OVER(ORDER BY m.OBJ_ID
            ASC,d.obj_id,cfcs.obj_id,cis.obj_id,pctv.obj_id,ctv.obj_id,c.OBJ_ID,ip.OBJ_ID,tv.OBJ_ID) AS OBJ_ID,
            CAST(p.ID_PSP AS VARCHAR(35)) PSP_ID,
            CAST(p.PSP_RAG_SOC AS VARCHAR(255)) PSP_RAG_SOC,
            CAST(
            CASE
            WHEN m.STORNO_PAGAMENTO = 0 THEN 'N'
            ELSE 'Y'
            END AS CHAR(1)
            ) PSP_FLAG_STORNO,
            CAST(
            CASE
            WHEN m.MARCA_BOLLO_DIGITALE = 1 AND cn.MARCA_BOLLO_DIGITALE = 'Y'
            THEN 'Y'
            ELSE 'N'
            END AS CHAR(1)
            ) PSP_FLAG_BOLLO,
            m.LOGO_PSP LOGO_PSP,
            CAST(m.ID_INFORMATIVA_PSP AS VARCHAR(35)) FLUSSO_ID,
            CAST(ip.ID_INTERMEDIARIO_PSP AS VARCHAR(35)) INTM_ID,
            CAST(c.ID_CANALE AS VARCHAR(35)) CANALE_ID,
            CAST(d.NOME_SERVIZIO AS VARCHAR(255)) NOME_SERVIZIO,
            CAST(
            (
            CASE cn.MODELLO_PAGAMENTO
            WHEN 'IMMEDIATO' THEN 0
            WHEN 'IMMEDIATO_MULTIBENEFICIARIO' THEN 1
            WHEN 'DIFFERITO' THEN 2
            WHEN 'ATTIVATO_PRESSO_PSP' THEN 4
            END
            ) AS NUMERIC(1, 0)
            ) CANALE_MOD_PAG,
            CAST(tv.TIPO_VERSAMENTO AS VARCHAR(15)) TIPO_VERS_COD,
            CAST(cis.CODICE_LINGUA AS CHAR(2)) CODICE_LINGUA,
            CAST(NULL AS VARCHAR(35)) INF_COND_EC_MAX,
            CAST(cis.DESCRIZIONE_SERVIZIO AS VARCHAR(140)) INF_DESC_SERV,
            CAST(cis.DISPONIBILITA_SERVIZIO AS VARCHAR(140)) INF_DISP_SERV,
            CAST(cis.URL_INFORMAZIONI_CANALE AS VARCHAR(140)) INF_URL_CANALE,
            sysdate AS TIMESTAMP_INS,
            CAST(m.DATA_INIZIO_VALIDITA AS timestamp) DATA_VALIDITA,
            CAST(cfcs.IMPORTO_MINIMO AS FLOAT) IMPORTO_MINIMO,
            CAST(cfcs.IMPORTO_MASSIMO AS FLOAT) IMPORTO_MASSIMO,
            CAST((cfcs.COSTO_FISSO + cfcs.VALORE_COMMISSIONE) AS FLOAT) COSTO_FISSO,
            CAST(d.TAGS AS VARCHAR(255)) TAGS,
            d.LOGO_SERVIZIO LOGO_SERVIZIO,
            CAST(
            CASE
            WHEN d.CANALE_APP = 0 THEN 'N'
            ELSE 'Y'
            END AS CHAR(1)
            ) CANALE_APP,
            cn.ON_US ON_US,
            cn.CARRELLO_CARTE CARRELLO_CARTE,
            p.ABI CODICE_ABI,
            p.CODICE_MYBANK CODICE_MYBANK,
            cfcs.CODICE_CONVENZIONE CODICE_CONVENZIONE,
            cn.FLAG_IO
            FROM ${schema}.CDI_MASTER m
            JOIN ${schema}.CDI_DETAIL d ON d.FK_CDI_MASTER = m.OBJ_ID
            JOIN ${schema}.CDI_FASCIA_COSTO_SERVIZIO cfcs ON cfcs.FK_CDI_DETAIL = d.OBJ_ID
            JOIN ${schema}.CDI_INFORMAZIONI_SERVIZIO cis ON cis.FK_CDI_DETAIL = d.OBJ_ID
            JOIN cte p ON m.OBJ_ID = p.ID_CDI_MASTER
            JOIN ${schema}.PSP_CANALE_TIPO_VERSAMENTO pctv ON pctv.OBJ_ID = d.FK_PSP_CANALE_TIPO_VERSAMENTO
            JOIN ${schema}.CANALE_TIPO_VERSAMENTO ctv ON ctv.OBJ_ID = pctv.FK_CANALE_TIPO_VERSAMENTO
            JOIN ${schema}.CANALI c ON c.OBJ_ID = ctv.FK_CANALE
            JOIN ${schema}.CANALI_NODO cn ON c.FK_CANALI_NODO = cn.OBJ_ID
            JOIN ${schema}.INTERMEDIARI_PSP ip ON c.FK_INTERMEDIARIO_PSP = ip.OBJ_ID
            JOIN ${schema}.TIPI_VERSAMENTO tv ON ctv.FK_TIPO_VERSAMENTO = tv.OBJ_ID
            WHERE c.CANALE_NODO = 'Y' AND C.ENABLED = 'Y' AND ip.enabled='Y';
CREATE FORCE EDITIONABLE VIEW "${schema}"."CDI_PREFERENCES_VIEW" ("OBJ_ID", "SELLER", "BUYER", "COSTO_CONVENZIONE", "ID_CDI_MASTER") AS
  (
            SELECT
            pr.OBJ_ID OBJ_ID,
            pr.SELLER SELLER,
            pr.BUYER BUYER,
            pr.COSTO_CONVENZIONE COSTO_CONVENZIONE,
            MAX(mas.OBJ_ID) ID_CDI_MASTER
            FROM ${schema}.CDI_PREFERENCES pr
            INNER JOIN ${schema}.CDI_DETAIL det ON det.OBJ_ID = pr.FK_INFORMATIVA_DETAIL
            INNER JOIN ${schema}.CDI_MASTER mas ON mas.OBJ_ID = det.FK_CDI_MASTER
            WHERE mas.DATA_INIZIO_VALIDITA < sysdate +1
            GROUP BY pr.OBJ_ID, pr.SELLER, pr.BUYER, pr.COSTO_CONVENZIONE
            );
CREATE FORCE EDITIONABLE VIEW "${schema}"."IBAN_VALIDI_PER_PA" ("FK_PA", "IBAN_ACCREDITO", "DATA_INIZIO_VALIDITA", "DATA_PUBBLICAZIONE", "RAGIONE_SOCIALE", "ID_MERCHANT", "ID_BANCA_SELLER", "CHIAVE_AVVIO", "CHIAVE_ESITO", "OBJ_ID", "MASTER_OBJ") AS
  select
    mas.FK_PA,
    det.IBAN_ACCREDITO,
    mas.DATA_INIZIO_VALIDITA,
    mas.DATA_PUBBLICAZIONE,
    mas.RAGIONE_SOCIALE,
    nullif(det.ID_MERCHANT, '') ID_MERCHANT,
    nullif(det.ID_BANCA_SELLER,'') ID_BANCA_SELLER,
    nullif(det.CHIAVE_AVVIO,'') CHIAVE_AVVIO,
    nullif(det.CHIAVE_ESITO,'') CHIAVE_ESITO,
    det.OBJ_ID OBJ_ID,
    mas.OBJ_ID MASTER_OBJ
  from INFORMATIVE_CONTO_ACCREDITO_MASTER mas
  inner join (
  select
     max(OBJ_ID) OBJ_ID
     FROM INFORMATIVE_CONTO_ACCREDITO_MASTER
     where DATA_INIZIO_VALIDITA <= CURRENT_TIMESTAMP
     GROUP BY FK_PA
     HAVING max(DATA_INIZIO_VALIDITA) <= CURRENT_TIMESTAMP
     )  right_id_by_pk
  on mas.OBJ_ID = right_id_by_pk.OBJ_ID
  inner join INFORMATIVE_CONTO_ACCREDITO_DETAIL det
  on mas.OBJ_ID = det.FK_INFORMATIVA_CONTO_ACCREDITO_MASTER;
CREATE FORCE EDITIONABLE VIEW "${schema}"."PSP_CANALE_TIPO_VERSAMENTO_CANALE" ("OBJ_ID", "FK_PSP", "FK_CANALE", "FK_TIPO_VERSAMENTO") AS
  SELECT pspctv.OBJ_ID,
        pspctv.FK_PSP,
        ctv.FK_CANALE,
        ctv.FK_TIPO_VERSAMENTO
    FROM psp_canale_tipo_versamento pspctv
        JOIN CANALE_TIPO_VERSAMENTO ctv
        ON pspctv.FK_CANALE_TIPO_VERSAMENTO = ctv.OBJ_ID;