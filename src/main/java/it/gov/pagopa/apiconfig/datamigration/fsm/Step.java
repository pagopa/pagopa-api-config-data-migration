package it.gov.pagopa.apiconfig.datamigration.fsm;

import it.gov.pagopa.apiconfig.datamigration.entity.DataMigration;
import it.gov.pagopa.apiconfig.datamigration.entity.DataMigrationDetails;
import it.gov.pagopa.apiconfig.datamigration.entity.DataMigrationStatus;
import it.gov.pagopa.apiconfig.datamigration.enumeration.MigrationStepStatus;
import it.gov.pagopa.apiconfig.datamigration.enumeration.StepName;
import it.gov.pagopa.apiconfig.datamigration.exception.migration.InvalidMigrationStatusException;
import it.gov.pagopa.apiconfig.datamigration.exception.migration.MigrationInterruptedStepException;
import it.gov.pagopa.apiconfig.datamigration.exception.migration.MigrationStepException;
import it.gov.pagopa.apiconfig.datamigration.repository.postgres.CfgDataMigrationRepository;
import it.gov.pagopa.apiconfig.datamigration.util.CommonUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;

import java.sql.Timestamp;
import java.util.concurrent.Callable;

@Slf4j
public abstract class Step implements Callable<StepName> {

    protected FSMSharedState sharedState;

    protected CfgDataMigrationRepository cfgDataMigrationRepo;

    public abstract void executeStep() throws MigrationStepException;

    public abstract StepName getNextState();

    public abstract String getStepName();

    public abstract DataMigrationStatus getDataMigrationStatus(DataMigrationDetails details);

    @Override
    public StepName call() {
        long startTime = System.currentTimeMillis();
        StepName nextState = getNextState();
        log.info(String.format("The step [%s] is starting its execution.", getStepName()));
        try {
            executeStep();
        } catch (MigrationInterruptedStepException e) {
            log.info(String.format("The step [%s] is interrupted gracefully. Next step will be END step.", getStepName()));
            nextState = StepName.END;
        } catch (MigrationStepException e) {
            log.error(String.format("The step [%s] is in error. Next step will be ERROR step.", getStepName()));
            nextState = StepName.ERROR;
        }
        log.info(String.format("The step [%s] ended its execution in [%d] ms.", getStepName(), (System.currentTimeMillis() - startTime)));
        return nextState;
    }

    public void attachSharedState(FSMSharedState fsm, CfgDataMigrationRepository repository) {
        this.sharedState = fsm;
        this.cfgDataMigrationRepo = repository;
    }

    protected boolean canContinueReadPages(Pageable pageable) {
        return !this.sharedState.isBlockRequested() && this.sharedState.isInLock() && pageable.isPaged();
    }

    protected void checkExecutionBlock(CfgDataMigrationRepository cfgDataMigrationRepo, boolean updateStatus) throws MigrationInterruptedStepException, InvalidMigrationStatusException {
        if (this.sharedState.isBlockRequested()) {
            if (updateStatus) {
                updateDataMigrationStatusOnBlock(cfgDataMigrationRepo);
            }
            throw new MigrationInterruptedStepException();
        }
    }

    protected void updateDataMigrationStatusOnStart(CfgDataMigrationRepository cfgDataMigrationRepo) throws InvalidMigrationStatusException {
        updateDataMigrationStatus(cfgDataMigrationRepo, MigrationStepStatus.IN_PROGRESS, CommonUtils.now(), null);
    }

    protected void updateDataMigrationStatusOnEnd(CfgDataMigrationRepository cfgDataMigrationRepo) throws InvalidMigrationStatusException {
        updateDataMigrationStatus(cfgDataMigrationRepo, MigrationStepStatus.COMPLETED, null, CommonUtils.now());
    }

    protected void updateDataMigrationStatusOnStepEnd(CfgDataMigrationRepository cfgDataMigrationRepo) throws InvalidMigrationStatusException {
        if (this.sharedState.isBlockRequested()) {
            updateDataMigrationStatusOnBlock(cfgDataMigrationRepo);
        } else {
            updateDataMigrationStatusOnEnd(cfgDataMigrationRepo);
        }
    }

    protected void updateDataMigrationStatusOnFailure(CfgDataMigrationRepository cfgDataMigrationRepo) throws InvalidMigrationStatusException {
        updateDataMigrationStatus(cfgDataMigrationRepo, MigrationStepStatus.FAILED, null, CommonUtils.now());
    }

    protected void updateDataMigrationStatusOnBlock(CfgDataMigrationRepository cfgDataMigrationRepo) throws InvalidMigrationStatusException {
        updateDataMigrationStatus(cfgDataMigrationRepo, MigrationStepStatus.BLOCKED, null, CommonUtils.now());
    }

    private void updateDataMigrationStatus(CfgDataMigrationRepository cfgDataMigrationRepo, MigrationStepStatus stepStatus, Timestamp start, Timestamp end) throws InvalidMigrationStatusException {
        DataMigration dataMigration = cfgDataMigrationRepo.findById(this.sharedState.getDataMigrationStateId()).orElseThrow(InvalidMigrationStatusException::new);
        dataMigration.setLastExecutedStep(getStepName());
        DataMigrationStatus migrationStatus = getDataMigrationStatus(dataMigration.getDetails());
        migrationStatus.setStatus(stepStatus.toString());
        if (start != null) {
            migrationStatus.setStart(start);
        }
        if (end != null) {
            migrationStatus.setEnd(end);
        }
        cfgDataMigrationRepo.saveAndFlush(dataMigration);
    }
}
