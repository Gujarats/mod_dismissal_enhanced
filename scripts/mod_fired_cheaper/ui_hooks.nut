::FiredCheaper.applyUIHooks <- function( _mod )
{
	_mod.hook("scripts/ui/global/data_helper", function( q )
	{
		q.addCharacterToUIData = @(__original) function( _entity, _target )
		{
			__original(_entity, _target);

			_target.firedCheaperDebug <- "ui hook reached";

			if (_entity == null)
			{
				_target.firedCheaperDebug <- "ui hook reached; entity is null";
				return;
			}

			if (!::FiredCheaper.ensureCalculatorLoaded())
			{
				_target.firedCheaperDebug <- "ui hook reached; calculator unavailable";
				return;
			}

			try
			{
				_target.firedCheaperDebug <- "ui hook reached; before attach methods";
				::FiredCheaper.attachCompensationMethods(_entity);

				_target.firedCheaperDebug <- "ui hook reached; before compensation cost";
				_target.compensationCost <- _entity.getCompensationCost();

				_target.firedCheaperDebug <- "ui hook reached; before compensation breakdown";
				_target.compensationBreakdown <- ::FiredCheaper.getCompensationBreakdown(_entity);

				_target.firedCheaperDebug <- "ui hook reached; before breakdown lines";
				_target.compensationBreakdownLines <- ::FiredCheaper.getCompensationBreakdownLines(_entity);

				_target.firedCheaperDebug <- "ui hook reached; before checkbox setting";
				_target.showCompensationCheckbox <- ::FiredCheaper.getSettingValue("EnableCompensationPaymentCheckbox");

				_target.firedCheaperDebug <- "ui hook reached; compensation payload attached; calculator source: " + ::FiredCheaper.CalculatorSource;
				if (("LastCalculatorIncludeError" in ::FiredCheaper) && ::FiredCheaper.LastCalculatorIncludeError != null)
				{
					_target.firedCheaperDebug += "; include error: " + ::FiredCheaper.LastCalculatorIncludeError;
				}
			}
			catch (e)
			{
				_target.firedCheaperDebug <- "ui hook reached; compensation payload error: " + e;
				if (("LastCalculatorIncludeError" in ::FiredCheaper) && ::FiredCheaper.LastCalculatorIncludeError != null)
				{
					_target.firedCheaperDebug += "; include error: " + ::FiredCheaper.LastCalculatorIncludeError;
				}
			}
		}
	});
}
