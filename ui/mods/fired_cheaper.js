(function()
{
    if (typeof CharacterScreenLeftPanelHeaderModule === 'undefined')
    {
        return;
    }

    CharacterScreenLeftPanelHeaderModule.prototype.createDismissDialogContent = function (_dialog)
    {
        var self = this;
        var data = this.mDataSource.getSelectedBrother();
        var selectedBrother = CharacterScreenIdentifier.Entity.Character.Key in data ? data[CharacterScreenIdentifier.Entity.Character.Key] : null;

        if (selectedBrother === null)
        {
            console.error('Failed to create dialog content. Reason: No brother selected.');
            return null;
        }

        var result = $('<div class="dismiss-character-container"/>');
        var showCheckbox = selectedBrother['showCompensationCheckbox'] !== false;
        var hasCompensationCost = selectedBrother['compensationCost'] !== undefined && selectedBrother['compensationCost'] !== null;
        var breakdownLines = selectedBrother['compensationBreakdownLines'] || [];
        var compensationCost = hasCompensationCost ? selectedBrother['compensationCost'] : 10 * Math.max(1, selectedBrother['daysWithCompany'] || 0);
        var paymentVerb = selectedBrother['dailyMoneyCost'] == 0 ? 'Reparations' : 'Compensation';
        var titleLabel;

        if (selectedBrother['dailyMoneyCost'] == 0)
            titleLabel = $('<div class="title-label title-font-normal font-bold font-color-title">Really free ' + selectedBrother[CharacterScreenIdentifier.Entity.Character.Name] + '?</div>');
        else
            titleLabel = $('<div class="title-label title-font-normal font-bold font-color-title">Really dismiss ' + selectedBrother[CharacterScreenIdentifier.Entity.Character.Name] + '?</div>');

        result.append(titleLabel);

        var textLabel = $('<div class="label text-font-medium font-color-description font-style-normal">' + selectedBrother[CharacterScreenIdentifier.Entity.Character.Name] + ' will permanently leave you and place his <br/>current equipment in the stash.</div>');
        result.append(textLabel);

        var retirementPackage = $('<div class="retirement-package"/>');
        result.append(retirementPackage);

        if (showCheckbox)
        {
            var checkbox = $('<input type="checkbox" class="compensation-checkbox" id="compensation" checked="true" name="display"/>');
            retirementPackage.append(checkbox);

            var checkboxLabel = $('<label class="blub text-font-medium font-color-subtitle font-style-normal" for="compensation">Pay <img src="' + Path.GFX + Asset.ICON_MONEY_SMALL + '"/>' + compensationCost + ' ' + paymentVerb + '</label>');
            retirementPackage.append(checkboxLabel);

            checkboxLabel.bindTooltip({ contentType: 'ui-element', elementId: TooltipIdentifier.CharacterScreen.DismissPopupDialog.Compensation });

            checkbox.iCheck({
                checkboxClass: 'icheckbox_flat-orange',
                radioClass: 'iradio_flat-orange',
                increaseArea: '0%'
            });

            checkbox.on('ifChecked ifUnchecked', null, this, function (_event)
            {
                self.mPayDismissalWage = checkbox.prop('checked') === true;
            });
        }
        else
        {
            self.mPayDismissalWage = true;
            retirementPackage.append($('<div class="label text-font-medium font-color-subtitle font-style-normal">Pay <img src="' + Path.GFX + Asset.ICON_MONEY_SMALL + '"/>' + compensationCost + ' ' + paymentVerb + '</div>'));
        }

        var breakdownContainer = $('<div class="retirement-package"/>');
        result.append(breakdownContainer);
        breakdownContainer.append($('<div class="label text-font-medium font-color-description font-style-normal">Compensation breakdown</div>'));

        if (breakdownLines.length === 0 && hasCompensationCost)
        {
            breakdownLines = ['Final compensation: ' + compensationCost];
        }
        else if (breakdownLines.length === 0)
        {
            breakdownLines = ['Fired Cheaper data unavailable; showing vanilla compensation fallback: ' + compensationCost];
        }

        for (var i = 0; i < breakdownLines.length; ++i)
        {
            var line = $('<div class="label text-font-small font-color-description font-style-normal"/>');
            line.text(breakdownLines[i]);
            breakdownContainer.append(line);
        }

        return result;
    };
})();
