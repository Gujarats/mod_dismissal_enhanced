::FiredCheaper.applyDismissHooks <- function( _mod )
{
	_mod.hook("scripts/ui/screens/character/character_screen", function( q )
	{
		q.onDismissCharacter = @(__original) function( _data )
		{
			::FiredCheaper.ensureCalculatorLoaded();

			local bro = this.Tactical.getEntityByID(_data[0]);
			local payCompensation = _data[1];
			local allowCheckbox = ::FiredCheaper.getSettingValue("EnableCompensationPaymentCheckbox");
			local enableExtras = ::FiredCheaper.getSettingValue("EnableExtraDismissalBehaviors");

			if (!allowCheckbox)
			{
				payCompensation = true;
			}

			if (bro != null)
			{
				bro.getSkills().onDismiss();
				this.World.Statistics.getFlags().increment("BrosDismissed");

				if (bro.getSkills().hasSkillOfType(this.Const.SkillType.PermanentInjury) && bro.getBackground().getID() != "background.slave")
				{
					this.World.Statistics.getFlags().increment("BrosWithPermanentInjuryDismissed");
				}

				if (payCompensation)
				{
					this.World.Assets.addMoney(-::FiredCheaper.getCompensationCost(bro));

					if (enableExtras && bro.getBackground().getID() == "background.slave")
					{
						local playerRoster = this.World.getPlayerRoster().getAll();

						foreach( other in playerRoster )
						{
							if (bro.getID() == other.getID())
							{
								continue;
							}

							if (other.getBackground().getID() == "background.slave")
							{
								other.improveMood(this.Const.MoodChange.SlaveCompensated, "Glad to see " + bro.getName() + " get reparations for his time");
							}
						}
					}
				}
				else if (enableExtras && bro.getBackground().getID() == "background.slave")
				{
				}
				else if (enableExtras && bro.getLevel() >= 11 && !this.World.Statistics.hasNews("dismiss_legend") && this.World.getPlayerRoster().getSize() > 1)
				{
					local news = this.World.Statistics.createNews();
					news.set("Name", bro.getName());
					this.World.Statistics.addNews("dismiss_legend", news);
				}
				else if (enableExtras && bro.getDaysWithCompany() >= 50 && !this.World.Statistics.hasNews("dismiss_veteran") && this.World.getPlayerRoster().getSize() > 1 && this.Math.rand(1, 100) <= 33)
				{
					local news = this.World.Statistics.createNews();
					news.set("Name", bro.getName());
					this.World.Statistics.addNews("dismiss_veteran", news);
				}
				else if (enableExtras && bro.getLevel() >= 3 && bro.getSkills().hasSkillOfType(this.Const.SkillType.PermanentInjury) && !this.World.Statistics.hasNews("dismiss_injured") && this.World.getPlayerRoster().getSize() > 1 && this.Math.rand(1, 100) <= 33)
				{
					local news = this.World.Statistics.createNews();
					news.set("Name", bro.getName());
					this.World.Statistics.addNews("dismiss_injured", news);
				}
				else if (enableExtras && bro.getDaysWithCompany() >= 7)
				{
					local playerRoster = this.World.getPlayerRoster().getAll();

					foreach( other in playerRoster )
					{
						if (bro.getID() == other.getID())
						{
							continue;
						}

						if (bro.getDaysWithCompany() >= 50)
						{
							other.worsenMood(this.Const.MoodChange.VeteranDismissed, "Dismissed " + bro.getName());
						}
						else
						{
							other.worsenMood(this.Const.MoodChange.BrotherDismissed, "Dismissed " + bro.getName());
						}
					}
				}

				if (("State" in this.World) && this.World.State != null && this.World.Assets.getOrigin().getID() == "scenario.manhunters")
				{
					local playerRoster = this.World.getPlayerRoster().getAll();
					local indebted = 0;
					local nonIndebted = [];

					foreach( bro in playerRoster )
					{
						if (bro.getBackground().getID() == "background.slave")
						{
							indebted++;
						}
						else
						{
							nonIndebted.push(bro);
						}
					}

					this.World.Statistics.getFlags().set("ManhunterIndebted", indebted);
					this.World.Statistics.getFlags().set("ManhunterNonIndebted", nonIndebted.len());
				}

				bro.getItems().transferToStash(this.World.Assets.getStash());
				this.World.getPlayerRoster().remove(bro);
				this.loadData();
				this.World.State.updateTopbarAssets();
			}
		}
	});
}
