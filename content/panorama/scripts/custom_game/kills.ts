class KillsUI {
    // Instance variables
    panel: Panel;

    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChildTraverse("PreGameSettingsContainer")

        this.killsContainer = this.container.FindChildTraverse("Kills")
        
        //this.container.RemoveAndDeleteChildren();

        this.header = this.panel.FindChildTraverse("Header")
        this.instructions = this.panel.FindChildTraverse("Instructions")
        this.discord = this.instructions.FindChildTraverse("Discord")
        this.wechat = this.instructions.FindChildTraverse("WeChat")

        let _this = this

        GameEvents.Subscribe("on_connect_full", this.onConnectFull)

        // Discord
        this.discord.SetPanelEvent(
          "onmouseover", 
          function(){
            $.DispatchEvent("DOTAShowTextTooltip", _this.discord, $.Localize("#pregame_discord_info"));
          }
        )

        this.discord.SetPanelEvent(
          "onmouseout", 
          function(){
            $.DispatchEvent("DOTAHideTextTooltip", _this.discord);
          }
        )

        this.discord.SetPanelEvent(
          "onmouseactivate", 
          function(){
            $.DispatchEvent('ExternalBrowserGoToURL', 'https://discord.gg/FT9Jkmydqv');
          }
        )

        // WeChat
        this.wechat.SetPanelEvent(
          "onmouseover", 
          function(){
            $.DispatchEvent("DOTAShowTextTooltip", _this.wechat, $.Localize("#pregame_wechat_info"));
          }
        )

        this.wechat.SetPanelEvent(
          "onmouseout", 
          function(){
            $.DispatchEvent("DOTAHideTextTooltip", _this.wechat);
          }
        )

        this.header.text = $.Localize("#difficulty_select")

        this.timerPanel = new KillsSelection(this.killsContainer, $.Localize("#difficulty_easy"), "Easy")
        this.timerPanel2 = new KillsSelection(this.killsContainer, $.Localize("#difficulty_normal"), "Normal")
        this.timerPanel3 = new KillsSelection(this.killsContainer, $.Localize("#difficulty_hard"), "Hard")
        //this.timerPanel4 = new KillsSelection(this.container, $.Localize("#difficulty_unfair"), "Unfair")
        this.timerPanel6 = new KillsSelection(this.killsContainer, $.Localize("#difficulty_impossible"), "Impossible")
        this.timerPanel7 = new KillsSelection(this.killsContainer, $.Localize("#difficulty_infinity"), "HELL")
        this.timerPanel8 = new KillsSelection(this.killsContainer, $.Localize("#difficulty_hardcore"), "HARDCORE")

        /// wave
        /*
        this.containerWave = this.panel.FindChild("VoteForWave")

        this.waveOption = new WaveSelection(this.containerWave, $.Localize("#waves_yes"), "Enable")
        this.waveOption2 = new WaveSelection(this.containerWave, $.Localize("#waves_no"), "Disable")
        */

        // effects
        this.containerEffects = this.panel.FindChildTraverse("VoteForEffects")
        this.buttonContainer = $.CreatePanel("Panel", this.containerEffects, "VoteButtonContainer");

        //this.effectOption = new EffectSelection(this.buttonContainer, $.Localize("#effects_yes"), "Enable")

        //fast bosses
        this.fastBossesOption = new FastBossesSelection(this.buttonContainer, $.Localize("#fast_bosses_yes"), "Enable")

        //double gold
        this.goldOption = new GoldSelection(this.buttonContainer, $.Localize("#gold_yes"), "Enable")

        //double xp
        this.expOption = new ExpSelection(this.buttonContainer, $.Localize("#exp_yes"), "Enable")

        $.Msg(panel); // Print the panel
    }

    onConnectFull = (data) => {
      let isHost = data.isHost;

      if(!isHost) {
        //
        let exists = this.container.FindChildTraverse("HostNotice")
        if(!exists) {
          let hostNotice = $.CreatePanel("Panel", this.container, "HostNotice");
          let warning = $.CreatePanel("Label", hostNotice, "HostNoticeWarning");

          this.container.MoveChildBefore(hostNotice, this.container.FindChildTraverse("Kills"))

          warning.html = true
          warning.text = $.Localize("#not_the_host_info");
        }

        let kills = this.container.FindChildTraverse("Kills")
        if(kills) {
          kills.style.opacity = "0.25"
        }

        let options = this.container.FindChildTraverse("VoteForEffects")
        if(options) {
          options.style.opacity = "0.25"
        }
      }
  }
}

let ui = new KillsUI($.GetContextPanel());
