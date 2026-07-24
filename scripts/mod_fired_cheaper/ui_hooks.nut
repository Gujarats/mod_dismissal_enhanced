::FiredCheaper.applyUIHooks <- function( _mod )
{
	_mod.hook("scripts/ui/global/data_helper", function( q )
	{
		q.addCharacterToUIData = @(__original) function( _entity, _target )
		{
			__original(_entity, _target);

			if (::MSU.isKindOf(_entity, "player"))
			{
				::FiredCheaper.ensureCalculatorLoaded();

				_target.compensationCost <- ::FiredCheaper.getCompensationCost(_entity);
				_target.compensationBreakdown <- ::FiredCheaper.getCompensationBreakdown(_entity);
				_target.compensationBreakdownLines <- ::FiredCheaper.getCompensationBreakdownLines(_entity);
				_target.showCompensationCheckbox <- ::FiredCheaper.getSettingValue("EnableCompensationPaymentCheckbox");
			}
		}
	});
}
