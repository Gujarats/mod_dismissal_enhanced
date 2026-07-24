::FiredCheaper.applyUIHooks <- function( _mod )
{
	_mod.hook("scripts/ui/global/data_helper", function( q )
	{
		q.addCharacterToUIData = @(__original) function( _entity, _target )
		{
			__original(_entity, _target);

			if (_entity != null && _target.isPlayerCharacter)
			{
				::FiredCheaper.attachCompensationMethods(_entity);

				_target.compensationCost <- _entity.getCompensationCost();
				_target.compensationBreakdown <- ::FiredCheaper.getCompensationBreakdown(_entity);
				_target.compensationBreakdownLines <- ::FiredCheaper.getCompensationBreakdownLines(_entity);
				_target.showCompensationCheckbox <- ::FiredCheaper.getSettingValue("EnableCompensationPaymentCheckbox");
			}
		}
	});
}
