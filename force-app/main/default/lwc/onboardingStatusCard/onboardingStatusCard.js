import { LightningElement, api } from 'lwc';

export default class OnboardingStatusCard extends LightningElement {
    @api value;

    get employeeName() {
        return this.value?.employeeName ?? '';
    }

    get department() {
        return this.value?.department ?? '';
    }

    get officeLocation() {
        return this.value?.officeLocation ?? '';
    }

    get itStatus() {
        return this.value?.itStatus ?? '';
    }

    get hrStatus() {
        return this.value?.hrStatus ?? '';
    }

    get facilitiesStatus() {
        return this.value?.facilitiesStatus ?? '';
    }

    get overallStatus() {
        return this.value?.overallStatus ?? '';
    }

    get itSystems() {
        return this.splitCsv(this.itStatus);
    }

    get facilitiesItems() {
        return this.splitCsv(this.facilitiesStatus).map((part, index) => {
            const separatorIndex = part.indexOf(':');
            if (separatorIndex > -1) {
                return {
                    key: `facility-${index}`,
                    label: part.substring(0, separatorIndex).trim(),
                    value: part.substring(separatorIndex + 1).trim()
                };
            }
            return {
                key: `facility-${index}`,
                label: '',
                value: part
            };
        });
    }

    get isCompleted() {
        return (this.overallStatus || '').trim().toLowerCase() === 'completed';
    }

    get overallStatusLabel() {
        return this.isCompleted ? 'Completed' : 'In Progress';
    }

    get overallStatusBadgeClass() {
        return this.isCompleted
            ? 'onboarding-card__status-badge onboarding-card__status-badge_completed'
            : 'onboarding-card__status-badge onboarding-card__status-badge_in-progress';
    }

    splitCsv(value) {
        return (value || '')
            .split(',')
            .map((part) => part.trim())
            .filter((part) => part.length > 0);
    }
}