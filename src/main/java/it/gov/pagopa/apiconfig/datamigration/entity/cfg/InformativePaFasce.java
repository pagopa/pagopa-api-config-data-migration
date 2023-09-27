package it.gov.pagopa.apiconfig.datamigration.entity.cfg;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@ToString
@Entity
@Table(name = "INFORMATIVE_PA_FASCE")

public class InformativePaFasce {

    @Id
    @Column(name = "OBJ_ID", nullable = false)
    private Long id;

    @Column(name = "ORA_A", length = 35)
    private String oraA;

    @Column(name = "ORA_DA", length = 35)
    private String oraDa;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "FK_INFORMATIVA_PA_DETAIL", nullable = false)
    @ToString.Exclude
    private InformativePaDetail fkInformativaPaDetail;
}