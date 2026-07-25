::DismissalEnhanced.applyUIHooks <- function( _mod )
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

			if (!::DismissalEnhanced.ensureCalculatorLoaded())
			{
				_target.firedCheaperDebug <- "ui hook reached; calculator unavailable";
				return;
			}

			try
			{
				_target.firedCheaperDebug <- "ui hook reached; before attach methods";
				::DismissalEnhanced.attachCompensationMethods(_entity);

				_target.firedCheaperDebug <- "ui hook reached; before compensation cost";
				_target.compensationCost <- _entity.getCompensationCost();

				_target.firedCheaperDebug <- "ui hook reached; before compensation breakdown";
				_target.compensationBreakdown <- ::DismissalEnhanced.getCompensationBreakdown(_entity);

				_target.firedCheaperDebug <- "ui hook reached; before breakdown lines";
				_target.compensationBreakdownLines <- ::DismissalEnhanced.getCompensationBreakdownLines(_entity);

				_target.firedCheaperDebug <- "ui hook reached; before checkbox setting";
				_target.showCompensationCheckbox <- ::DismissalEnhanced.getSettingValue("EnableCompensationPaymentCheckbox");

				_target.firedCheaperDebug <- "ui hook reached; compensation payload attached; calculator source: " + ::DismissalEnhanced.CalculatorSource;
				if (("LastCalculatorIncludeError" in ::DismissalEnhanced) && ::DismissalEnhanced.LastCalculatorIncludeError != null)
				{
					_target.firedCheaperDebug += "; include error: " + ::DismissalEnhanced.LastCalculatorIncludeError;
				}
			}
			catch (e)
			{
				_target.firedCheaperDebug <- "ui hook reached; compensation payload error: " + e;
				if (("LastCalculatorIncludeError" in ::DismissalEnhanced) && ::DismissalEnhanced.LastCalculatorIncludeError != null)
				{
					_target.firedCheaperDebug += "; include error: " + ::DismissalEnhanced.LastCalculatorIncludeError;
				}
			}
		}
	});
}
