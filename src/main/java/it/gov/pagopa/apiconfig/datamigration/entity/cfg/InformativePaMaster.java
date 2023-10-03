package it.gov.pagopa.apiconfig.datamigration.entity.cfg;

import it.gov.pagopa.apiconfig.datamigration.util.NumericBooleanConverter;
import lombok.*;

import jakarta.persistence.*;
import java.sql.Timestamp;
import java.util.List;

@Table(name = "INFORMATIVE_PA_MASTER")
@Entity
@Getter
@Setter
@ToString
@Builder
@NoArgsConstructor
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class InformativePaMaster {

    @Id
    @Column(name = "OBJ_ID", nullable = false)
    private Long id;

    @Column(name = "ID_INFORMATIVA_PA", nullable = false, length = 35)
    private String idInformativaPa;

    @Column(name = "DATA_INIZIO_VALIDITA")
    private Timestamp dataInizioValidita;

    @Column(name = "DATA_PUBBLICAZIONE")
    private Timestamp dataPubblicazione;

    @Column(name = "FK_PA", nullable = false)
    private Long fkPa;

    @Column(name = "FK_BINARY_FILE")
    private Long fkBinaryFile;

    @Column(name = "VERSIONE", length = 35)
    private String versione;

    @Column(name = "PAGAMENTI_PRESSO_PSP")
    @Convert(converter = NumericBooleanConverter.class)
    private Boolean pagamentiPressoPsp;
}
