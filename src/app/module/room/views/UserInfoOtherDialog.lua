--
-- Author: tony
-- Date: 2014-08-04 11:30:13
--

local WIDTH = 670
local HEIGHT = 480
local LEFT = -WIDTH * 0.5
local TOP = HEIGHT * 0.5
local RIGHT = WIDTH * 0.5
local BOTTOM = -HEIGHT * 0.5
local LEFTOFFSET_X = 92

-- 4个赠送筹码 按钮赠送的数量，本变量用来控制显示和数值
local SEND_CHIP_1_AMOUNT = 10
local SEND_CHIP_2_AMOUNT = 100
local SEND_CHIP_3_AMOUNT = 500 -- 1000
local SEND_CHIP_4_AMOUNT = 1000 -- 10000
local SEND_CHIP_5_AMOUNT = 10000

local SEND_CHIP_3_AMOUNT_TXT = '500' -- 限制长度，方便显示
local SEND_CHIP_4_AMOUNT_TXT = '1K'
local SEND_CHIP_5_AMOUNT_TXT = '10K'
local TEXT_COLOR = cc.c3b(0xEE, 0xEE, 0xEE)

local StorePopup = import("app.module.newstore.StorePopup")
local AvatarIcon = import("boomegg.ui.AvatarIcon")
local UserAvatarPopup = import("app.module.room.views.UserAvatarPopup")
local DisplayUtil = import("boomegg.util.DisplayUtil")

local UserInfoOtherDialog = class("UserInfoOtherDialog", function()
    return nk.ui.Panel.new({WIDTH, HEIGHT})
end)

function UserInfoOtherDialog:ctor(ctx)
    self:addBgLight()
    self:addCloseBtn()
    self:setNodeEventEnabled(true)
    self.ctx = ctx
    self.isFriend_ = 0 --是否为好友关系，默认为否

    self.avatarSize = 100

    local left_offset_x = LEFTOFFSET_X
    self.avatarBg = display.newScale9Sprite("#pop_userinfo_avatar_bg.png", 0, 0, cc.size(self.avatarSize  + 2, self.avatarSize + 2), cc.rect(21, 18, 1, 1))
        :pos(LEFT + left_offset_x, TOP - 72)
        :addTo(self)
    self.avatarIcon_ = AvatarIcon.new("#common_male_avatar.png", self.avatarSize, self.avatarSize, 8, 
                {resId="#pop_userinfo_avatar_bg.png", size=cc.size(self.avatarSize,self.avatarSize)}, 1, 14, 0)
        :pos(self.avatarSize * 0.5, self.avatarSize * 0.5)
        :addTo(self.avatarBg)
    bm.TouchHelper.new(self.avatarIcon_, handler(self, self.onHeadImgContainerClick_))
    
    --性别图标背景
    self.sexIcon_ = display.newSprite("#pop_userinfo_sex_male.png"):pos(LEFT + 212, TOP - 48):addTo(self)
        --昵称
    self.nick_ = ui.newTTFLabel({size=24, color=cc.c3b(0xce, 0xe8, 0xff)})
    self.nick_:setAnchorPoint(cc.p(0, 0.5))
    self.nick_:pos(LEFT + 234, TOP - 48)
    self.nick_:addTo(self)
    --UID
    self.uid_ = ui.newTTFLabel({size=24, color=cc.c3b(0xce, 0xe8, 0xff)})
    self.uid_:setAnchorPoint(cc.p(0, 0.5))
    self.uid_:pos(LEFT + 408, TOP - 48)
    self.uid_:addTo(self)

    --筹码
    local label_pos_x = LEFT + 286
    local label_pos_y = TOP - 30 - 36 * 2
    local label_number_width = 180
    local label_number_height = 34
    local label_icon_offset_x = -72

    -- 筹码数值
    display.newScale9Sprite("#pop_userinfo_info_bg.png", 0, 0, cc.size(label_number_width, label_number_height), cc.rect(20, 1, 1, 1))
        :pos(label_pos_x, label_pos_y)
        :addTo(self)
    if self.ctx.model:isCoinRoom() then
        display.newSprite("#common_gcoin_icon.png")
            :pos(label_pos_x + label_icon_offset_x, label_pos_y)
            :addTo(self)
            :scale(0.82)
    else
        display.newSprite("#chip_icon.png")
            :pos(label_pos_x + label_icon_offset_x, label_pos_y)
            :addTo(self)
            :scale(0.82)
    end
    self.chip_ = ui.newTTFLabel({text = "" , color = TEXT_COLOR, size = 22, align = ui.TEXT_ALIGN_CENTER})
        :pos(label_pos_x + label_icon_offset_x + 20, label_pos_y-1)
        :addTo(self)
    self.chip_:setAnchorPoint(cc.p(0, 0.5))

    --等级
    label_pos_x = LEFT + 496
    display.newScale9Sprite("#pop_userinfo_info_bg.png", 0, 0, cc.size(label_number_width, label_number_height), cc.rect(20, 1, 1, 1))
        :pos(label_pos_x, label_pos_y)
        :addTo(self)
    display.newSprite("#level_icon.png")
        :pos(label_pos_x + label_icon_offset_x, label_pos_y)
        :addTo(self)
    self.level_ = ui.newTTFLabel({text = "" , color = TEXT_COLOR, size = 22, align = ui.TEXT_ALIGN_CENTER})
        :pos(label_pos_x + label_icon_offset_x + 20, label_pos_y)
        :addTo(self)
    self.level_:setAnchorPoint(cc.p(0, 0.5))


    --排名
    label_pos_x = LEFT + 200
    self.ranking_ = ui.newTTFLabel({size=24, color=cc.c3b(0xaa, 0xaa, 0xaa)})
    self.ranking_:setAnchorPoint(cc.p(0, 0.5))
    self.ranking_:pos(label_pos_x, TOP - 42 - 36 * 3)
    self.ranking_:addTo(self)

    --胜率
    self.winRate_ = ui.newTTFLabel({size=24, color=cc.c3b(0xaa, 0xaa, 0xaa)})
    self.winRate_:setAnchorPoint(cc.p(0, 0.5))
    self.winRate_:pos(label_pos_x + 208, TOP - 42 - 36 * 3)
    self.winRate_:addTo(self)

    local button_offset_x = 38
    --加好友按钮
    self.isAddFriend_ = true
    self.addFriendBtn_ = cc.ui.UIPushButton.new({
                normal = {"#pop_userinfo_other_green_normal.png", "#pop_userinfo_other_addFriends_add.png"},
                pressed = {"#pop_userinfo_other_green_pressed.png", "#pop_userinfo_other_addFriends_add.png"},
                disabled= {"#pop_userinfo_other_disable.png", "#pop_userinfo_other_addFriends_disable.png"},
            })
        -- :setButtonLabel(ui.newTTFLabel({text=bm.LangUtil.getText("ROOM", "ADD_FRIEND"), size=20, color=cc.c3b(0xFF, 0xFF, 0xFF)}))
        :onButtonClicked(buttontHandler(self, self.onFriendClicked_))
        :pos(LEFT + left_offset_x - button_offset_x, self.avatarBg:getPositionY() - 84)
        :setButtonEnabled(false)
        :addTo(self)

    self.toBtn_ = cc.ui.UIPushButton.new({normal = {"#pop_userinfo_other_blue_normal.png", "#chat_to_normal.png"}, pressed = {"#pop_userinfo_other_blue_pressed.png", "#chat_to_down.png"}})
        :pos(LEFT + left_offset_x + button_offset_x, self.avatarBg:getPositionY() - 84)
        :onButtonClicked(function()
            nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
            local curScene = display.getRunningScene()
            local ChatMsgPanel = import("app.module.room.views.ChatMsgPanel")
            local chatPanel = ChatMsgPanel.new(curScene.ctx,self.data_)
            chatPanel:showPanel()
            self:hide()
        end)
        :addTo(self)

    local send_chips_pos_y = -210
    self.forbidBtn_ = cc.ui.UIPushButton.new({normal = {"#pop_userinfo_other_yellow_normal.png", "#chat_forbid_xx.png"}, pressed = {"#pop_userinfo_other_yellow_pressed.png", "#chat_forbid_xx.png"}})
        :pos(LEFT + left_offset_x - button_offset_x, TOP + send_chips_pos_y)
        :onButtonClicked(function()
            nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
            local curScene = display.getRunningScene()
            if self.data_ and self.data_.uid and curScene and curScene.controller and curScene.controller.forbidChat then
                curScene.controller:forbidChat(self.data_.uid)
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "CHAT_SHIELD",self.data_.nick))
                self.forbidBtn_:hide()
                self.openBtn_:show()
            end
        end)
        :addTo(self)

    -- 解禁
    self.openBtn_ = cc.ui.UIPushButton.new({normal = {"#pop_userinfo_other_yellow_normal.png", "#chat_forbid_normal.png"}, pressed = {"#pop_userinfo_other_yellow_pressed.png", "#chat_forbid_normal.png"}})
        :pos(LEFT + left_offset_x - button_offset_x, TOP + send_chips_pos_y)
        :onButtonClicked(function()
            nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
            local curScene = display.getRunningScene()
            if self.data_ and self.data_.uid and curScene and curScene.controller and curScene.controller.forbidChat then
                if self.ctx.roomController and self.ctx.roomController.forbidChatList then
                    self.ctx.roomController.forbidChatList[self.data_.uid] = nil
                end
                self.forbidBtn_:show()
                self.openBtn_:hide()
            end
        end)
        :addTo(self)
    self.openBtn_:hide()

    self.kickBtn_ = cc.ui.UIPushButton.new({normal = {"#pop_userinfo_other_blue_normal.png", "#pop_userinfo_other_kickCard.png"}, 
                pressed = {"#pop_userinfo_other_blue_pressed.png", "#pop_userinfo_other_kickCard.png"},
                disabled = {"#pop_userinfo_other_disable.png", "#pop_userinfo_other_kickCard_disable.png"}})
        :pos(LEFT + left_offset_x + button_offset_x, TOP + send_chips_pos_y)
        :onButtonClicked(function()
            nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
            self:sendKickAndHide_()
        end)
        :addTo(self)

    self:updateKickData()

    --赠送筹码背景
    -- self.sendChipsBg_ = display.newScale9Sprite("#room_pop_userinfo_other_send_chips_bg.png", LEFT + left_offset_x + 4+124, TOP + send_chips_pos_y, cc.size(118, 44)):addTo(self)

    -- --赠送筹码标签
    -- self.sendChipLabel_ = ui.newTTFLabel({text=bm.LangUtil.getText("ROOM", "INFO_SEND_CHIPS"),size=24, color=cc.c3b(0xce, 0xe8, 0xff)})
    -- self.sendChipLabel_:pos(LEFT + left_offset_x+124, TOP + send_chips_pos_y)
    -- self.sendChipLabel_:addTo(self)

    --绿色筹码按钮1
    local labelOff_x, labelOff_y = -1, 0
    local offset_x = 136
    local distance_x = 90
    self.sendChipBtn1_ = cc.ui.UIPushButton.new("#chip_big_green.png")
        :setButtonLabel(ui.newTTFLabel({
            text=SEND_CHIP_1_AMOUNT,
            size=24, color=cc.c3b(0xca, 0xea, 0xd3)}))
        :setButtonLabelOffset(-2, 0)
        :onButtonPressed(function(event) end)
        :onButtonRelease(function(event) end)
        :onButtonClicked(function(event)
                nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                self:sendChipClicked_(SEND_CHIP_1_AMOUNT)
            end)
        :pos(LEFT + offset_x + distance_x, TOP + send_chips_pos_y)
        -- :scale(0.8)
        :addTo(self)

    --绿色筹码按钮2
    self.sendChipBtn2_ = cc.ui.UIPushButton.new("#chip_big_green.png")
        :setButtonLabel(ui.newTTFLabel({
            text=SEND_CHIP_2_AMOUNT,
            size=24, color=cc.c3b(0xca, 0xea, 0xd3)}))
        :setButtonLabelOffset(-1, 0)
        :onButtonPressed(function(event) end)
        :onButtonRelease(function(event) end)
        :onButtonClicked(function(event)
                nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                self:sendChipClicked_(SEND_CHIP_2_AMOUNT)
            end)
        :pos(LEFT + offset_x + distance_x * 2, TOP + send_chips_pos_y)
        -- :scale(0.8)
        :addTo(self)

    --红色筹码按钮3
    self.sendChipBtn3_ = cc.ui.UIPushButton.new("#chip_big_red.png")
        :setButtonLabel(ui.newTTFLabel({
            text=SEND_CHIP_3_AMOUNT_TXT,
            size=24, color=cc.c3b(0xfd, 0xe5, 0xe4)}))
        :onButtonPressed(function(event) end)
        :onButtonRelease(function(event) end)
        :onButtonClicked(function(event)
                nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                self:sendChipClicked_(SEND_CHIP_3_AMOUNT)
            end)
        :pos(LEFT + offset_x + distance_x * 3, TOP + send_chips_pos_y)
        -- :scale(0.8)
        :addTo(self)

    --红色筹码按钮4
    self.sendChipBtn4_ = cc.ui.UIPushButton.new("#chip_big_red.png")
        :setButtonLabel(ui.newTTFLabel({
            text=SEND_CHIP_4_AMOUNT_TXT,
            size=24, color=cc.c3b(0xfd, 0xe5, 0xe4)}))
        :setButtonLabelOffset(-1, 0)
        :onButtonPressed(function(event) end)
        :onButtonRelease(function(event) end)
        :onButtonClicked(function(event)
                nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                self:sendChipClicked_(SEND_CHIP_4_AMOUNT)
            end)
        :pos(LEFT + offset_x + distance_x * 4, TOP + send_chips_pos_y)
        -- :scale(0.8)
        :addTo(self)
    self.sendChipBtn5_ = cc.ui.UIPushButton.new("#chip_big_green.png")
        :setButtonLabel(ui.newTTFLabel({
            text=SEND_CHIP_5_AMOUNT_TXT,
            size=24, color=cc.c3b(0xfd, 0xe5, 0xe4)}))
        :setButtonLabelOffset(-1, 0)
        :onButtonPressed(function(event) end)
        :onButtonRelease(function(event) end)
        :onButtonClicked(function(event)
                nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                self:sendChipClicked_(SEND_CHIP_5_AMOUNT)
            end)
        :pos(LEFT + offset_x + distance_x * 5, TOP + send_chips_pos_y)
        -- :scale(0.8)
        :addTo(self)

    local curScene = display.getRunningScene()
    local noSendChip = self.ctx.model:isCoinRoom() or curScene.name == "MatchRoomScene" or self.ctx.model.isPDengRoom_
    if noSendChip then  
        DisplayUtil.setGray(self.sendChipBtn1_)
        DisplayUtil.setGray(self.sendChipBtn2_)
        DisplayUtil.setGray(self.sendChipBtn3_)
        DisplayUtil.setGray(self.sendChipBtn4_)
        DisplayUtil.setGray(self.sendChipBtn5_)

        self.sendChipBtn1_:setButtonEnabled(false)
        self.sendChipBtn2_:setButtonEnabled(false)
        self.sendChipBtn3_:setButtonEnabled(false)
        self.sendChipBtn4_:setButtonEnabled(false)
        self.sendChipBtn5_:setButtonEnabled(false)
    end

    self.isShowChip_ = nk.userData.isSendChips and nk.userData.isSendChips == 0
        
    -- ios 审核 isSendChips 为0 是下掉，isSendChips 为1 是打开
    if self.isShowChip_ then
        -- self.sendChipsBg_:opacity(0)
        -- self.sendChipLabel_:opacity(0)
        self.sendChipBtn1_:opacity(0)
        self.sendChipBtn2_:opacity(0)
        self.sendChipBtn3_:opacity(0)
        self.sendChipBtn4_:opacity(0)
    end

    --互动道具背景
    display.newScale9Sprite("#room_pop_userinfo_other_send_bg.png", 0, BOTTOM + 112, cc.size(WIDTH - 24, 245)):addTo(self)

    if nk.userData.songkranProps == 1 then
        self:addHddjList_new()
    elseif nk.userData.waterLampProps == 1 then
        self:addHddjList_waterlamp()
    else
        self:addHddjList_old()
    end
    
end

function UserInfoOtherDialog:addHddjList_old()
    local x, y = LEFT + LEFTOFFSET_X - 8, BOTTOM + 172
    for i = 1, 2 do
        for j = 1, 5 do
            local id = (i - 1) * 5 + j

            if id == 1 and nk.OnOff:check("halloweenAct") then
                --todo
                -- print("nk.OnOff:check.halloweenAct :" .. tostring(nk.OnOff:check("halloweenAct")))
                id = 17
            end

            local btn = cc.ui.UIPushButton.new({normal = "#pop_userinfo_my_bank_number_bg.png",pressed="#pop_userinfo_my_bank_number_pressed_bg.png"}, {scale9=true})
                :setButtonSize(90, 72)
                :onButtonClicked(function()
                        nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                        self:sendHddjClicked_(id)
                    end)
                :pos(x, y)
                :addTo(self)

            if id == 1 then
                btn:setButtonLabel(display.newSprite("#hddj_egg_icon.png"))
            elseif id == 10 then
                btn:setButtonLabel(display.newSprite("#hddj_tissue_icon.png"):scale(1.1))
            elseif id == 4 then
                btn:setButtonLabel(display.newSprite("#hddj_kiss_lip_icon.png"):scale(1.3))
            elseif id == 5 then
                btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.75))
            elseif id == 6 then
                btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.5))
            elseif id == 7 then
                btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(1.4))
            elseif id == 8 then
                btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.9))
            elseif id == 17 then
                --todo
                 btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"))
            else
                btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.6))
            end

            x = x + 124
        end
        x = LEFT + LEFTOFFSET_X - 8
        y = y - 102
    end
end

function UserInfoOtherDialog:addHddjList_new()
    local offx = 18
    local x, y = LEFT + LEFTOFFSET_X - 8, BOTTOM + 172
    local hddjIds = {201, 202, 203, 2, 3, 4, 5, 7, 8, 10}
    for i = 1, #hddjIds do
        local id = hddjIds[i]
        local btn = cc.ui.UIPushButton.new({normal = "#pop_userinfo_my_bank_number_bg.png",pressed="#pop_userinfo_my_bank_number_pressed_bg.png"}, {scale9=true})
            :setButtonSize(90, 72)
            :onButtonClicked(function()
                    nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                    self:sendHddjClicked_(id)
                end)
            :pos(x, y)
            :addTo(self)
        if id == 1 then
            btn:setButtonLabel(display.newSprite("#hddj_egg_icon.png"))
        elseif id == 10 then
            btn:setButtonLabel(display.newSprite("#hddj_tissue_icon.png"):scale(1.1))
        elseif id == 4 then
            btn:setButtonLabel(display.newSprite("#hddj_kiss_lip_icon.png"):scale(1.3))
        elseif id == 5 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.75))
        elseif id == 6 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.5))
        elseif id == 7 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(1.4))
        elseif id == 8 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.9))
        elseif id > 200 then
            btn:setButtonLabel(display.newSprite("songkran_hddj_" .. id .. ".png"))
            display.newSprite("holiday_prop_mark.png"):pos(5, -30):addTo(btn)
        else
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.6))
        end

         if i % 5 == 0 then
            x = LEFT + LEFTOFFSET_X - 8
            y = y - 102
        else
            x = x + 124
        end 
    end
end

function UserInfoOtherDialog:addHddjList_waterlamp()
    local offx = 18
    local x, y = LEFT + LEFTOFFSET_X - 8, BOTTOM + 172
    local hddjIds = {1, 2, 3, 4, 5, 6, 7, 8, 1009, 1010}
    for i = 1, #hddjIds do
        local id = hddjIds[i]
        local btn = cc.ui.UIPushButton.new({normal = "#pop_userinfo_my_bank_number_bg.png",pressed="#pop_userinfo_my_bank_number_pressed_bg.png"}, {scale9=true})
            :setButtonSize(90, 72)
            :onButtonClicked(function()
                    nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON)
                    self:sendHddjClicked_(id)
                end)
            :pos(x, y)
            :addTo(self)
        if id == 1 then
            btn:setButtonLabel(display.newSprite("#hddj_egg_icon.png"))
        elseif id == 10 then
            btn:setButtonLabel(display.newSprite("#hddj_tissue_icon.png"):scale(1.1))
        elseif id == 4 then
            btn:setButtonLabel(display.newSprite("#hddj_kiss_lip_icon.png"):scale(1.3))
        elseif id == 5 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.75))
        elseif id == 6 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.5))
        elseif id == 7 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(1.4))
        elseif id == 8 then
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.9))
        elseif id == 1009 then
            btn:setButtonLabel(display.newSprite("#waterLampA.png"))
        elseif id == 1010 then
            btn:setButtonLabel(display.newSprite("#waterLampB.png"))
        else
            btn:setButtonLabel(display.newSprite("#hddj_" .. id .. ".png"):scale(0.6))
        end

         if i % 5 == 0 then
            x = LEFT + LEFTOFFSET_X - 8
            y = y - 102
        else
            x = x + 124
        end 
    end 
end

function UserInfoOtherDialog:show(data)
    self.data_ = data
    self:setData(data)
    self:showPanel_(true, true, true, true)
end

function UserInfoOtherDialog:onShowed()
    if self.openBtn_ and self.forbidBtn_ then
        if self.ctx.roomController and self.ctx.roomController.forbidChatList then
            local isForbid = false
            for k,v in pairs(self.ctx.roomController.forbidChatList) do
                if k==self.data_.uid then
                    if v then
                        isForbid = v
                    end
                    break
                end
            end
            if isForbid then
                self.openBtn_:show()
                self.forbidBtn_:hide()
            else
                self.openBtn_:hide()
                self.forbidBtn_:show()
            end
        else
            self.openBtn_:hide()
            self.forbidBtn_:show()
        end
    end
end

function UserInfoOtherDialog:hide()
    if self.rankingRequestId_ then
        bm.HttpService.CANCEL(self.rankingRequestId_)
    end
    if self.hddjNumObserverId_ then
        bm.DataProxy:removePropertyObserver(nk.dataKeys.USER_DATA, "hddjNum", self.hddjNumObserverId_)
        self.hddjNumObserverId_ = nil
    end
    nk.ImageLoader:cancelJobByLoaderId(self.headImageLoaderId_)
    self:hidePanel_()
end

function UserInfoOtherDialog:setAddFriendStatus()
    self.addFriendBtn_:setButtonEnabled(true)
    if self.isFriend_ == 0 then
        self.addFriendBtn_:setButtonImage("normal", {"#pop_userinfo_other_green_normal.png", "#pop_userinfo_other_addFriends_add.png"})
        self.addFriendBtn_:setButtonImage("pressed", {"#pop_userinfo_other_green_pressed.png", "#pop_userinfo_other_addFriends_add.png"})
        -- self.addFriendBtn_:setButtonLabelString(bm.LangUtil.getText("ROOM", "ADD_FRIEND"))
        self.isAddFriend_ = true
    else
        self.addFriendBtn_:setButtonImage("normal", {"#pop_userinfo_other_blue_normal.png", "#pop_userinfo_other_addFriends_cancel.png"})
        self.addFriendBtn_:setButtonImage("pressed", {"#pop_userinfo_other_blue_pressed.png", "#pop_userinfo_other_addFriends_cancel.png"})
        -- self.addFriendBtn_:setButtonLabelString(bm.LangUtil.getText("ROOM", "DEL_FRIEND"))
        self.isAddFriend_ = false
    end
end

function UserInfoOtherDialog:setData(data)
    self.data_ = data

    if data then
        self.nick_:setString(nk.Native:getFixedWidthText("", 24, data.nick, 150))
        self.uid_:setString(bm.LangUtil.getText("ROOM", "INFO_UID", data.uid))
        self.chip_:setString(bm.formatBigNumber(data.chips))
        self.level_:setString(bm.LangUtil.getText("ROOM", "INFO_LEVEL", data.level or nk.Level:getLevelByExp(data.exp)))
        self.winRate_:setString(bm.LangUtil.getText("ROOM", "INFO_WIN_RATE", data.win + data.lose > 0 and math.round(data.win * 100 / (data.win + data.lose)) or 0))
        data.ranking = nil
        if data.ranking then
            if data.ranking > 10000 then
                self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", ">10,000"))
            else
                self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", bm.formatNumberWithSplit(data.ranking)))
            end
        else
            self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", ".."))
            if self.rankingRequestId_ then
                bm.HttpService.CANCEL(self.rankingRequestId_)
            end
            self.rankingRequestId_ = bm.HttpService.POST({mod="user", act="othermain", puid=data.uid},
                function(data) 
                    self.rankingRequestId_ = nil
                    local callData = json.decode(data)
                    if callData then
                        if self.ctx.model:isCoinRoom() then
                            self.data_.chips = tonumber(callData.gcoins or 0) or self.data_.chips
                        else
                            self.data_.chips = tonumber(callData.money) or self.data_.chips
                        end
                        self.data_.level = tonumber(callData.level) or nk.Level:getLevelByExp(self.data_.exp)
                        self.data_.win = tonumber(callData.win) or self.data_.win
                        self.data_.lose = tonumber(callData.lose) or self.data_.lose
                        self.data_.ranking = tonumber(callData.rankMoney) or self.data_.ranking
                        self.data_.gender = callData.sex or self.data_.gender
                        if self.data_.gender == "f" then
                            self.sexIcon_:setSpriteFrame(display.newSpriteFrame("pop_userinfo_sex_female.png"))
                        else
                            self.sexIcon_:setSpriteFrame(display.newSpriteFrame("pop_userinfo_sex_male.png"))
                        end

                        if self.ctx.model:isCoinRoom() then
                            self.chip_:setString(bm.formatBigNumber(callData.gcoins or 0))
                        else
                            self.chip_:setString(bm.formatBigNumber(callData.money))
                        end
                        self.level_:setString(bm.LangUtil.getText("ROOM", "INFO_LEVEL", callData.level))
                        self.winRate_:setString(bm.LangUtil.getText("ROOM", "INFO_WIN_RATE", callData.win + callData.lose > 0 and math.round(callData.win * 100 / (callData.win + callData.lose)) or 0))
                        if callData.rankMoney > 10000 then
                            self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", ">10,000"))
                        else
                            self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", bm.formatNumberWithSplit(callData.rankMoney)))
                        end
                        self.isFriend_ = callData.fri
                        self:setAddFriendStatus()
                    end
                end, function()
                    self.rankingRequestId_ = nil
                    -- self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", "-"))
                end)
        end
        if data.gender == "f" then
            self.sexIcon_:setSpriteFrame(display.newSpriteFrame("pop_userinfo_sex_female.png"))
            self.avatarIcon_:setSpriteFrame("common_female_avatar.png")
        else
            self.sexIcon_:setSpriteFrame(display.newSpriteFrame("pop_userinfo_sex_male.png"))
            self.avatarIcon_:setSpriteFrame("common_male_avatar.png")
        end
        local imgurl = data.img
        if string.find(imgurl, "facebook") then
            if string.find(imgurl, "?") then
                imgurl = imgurl .. "&width=200&height=200"
            else
                imgurl = imgurl .. "?width=200&height=200"
            end
        end
        self.avatarIcon_:loadImage(imgurl)

        if data.seatId and data.seatId == 9 then
            self.kickBtn_:hide()
        end
    else
        self.nick_:setString("")
        self.uid_:setString(bm.LangUtil.getText("ROOM", "INFO_UID", ""))
        self.chip_:setString("")
        self.level_:setString(bm.LangUtil.getText("ROOM", "INFO_LEVEL", 1))
        self.winRate_:setString(bm.LangUtil.getText("ROOM", "INFO_WIN_RATE", 0))
        self.ranking_:setString(bm.LangUtil.getText("ROOM", "INFO_RANKING", ""))
        self.sexIcon_:setSpriteFrame(display.newSpriteFrame("pop_userinfo_sex_male.png"))

    end
    self:setAddFriendStatus()

    local level = data.vip or 0
    if data.vipmsg and data.vipmsg.vip then
        level = data.vipmsg.vip.level or 0
    end
    
    self.avatarIcon_:renderOtherVIP(level)
end

function UserInfoOtherDialog:onFriendClicked_(evt)
    if self.isAddFriend_ then
        self:onAddFriendClicked_(evt)
    else
        self:onDelFriendClicked_(evt)
    end
end

function UserInfoOtherDialog:onAddFriendClicked_(evt)
    self.addFriendBtn_:setButtonEnabled(false)
    bm.HttpService.POST({mod="friend", act="setPoker", fuid=self.data_.uid, new = 1}, function(data)
        local retData = json.decode(data)
        if retData then
            if retData.ret == 1 or retData.ret == 2 then
                if self.ctx.model:isSelfInSeat() then
                    --自己在座位，广播加好友动画
                    if self.ctx.model.isPDengRoom_ then
                        nk.socket.RoomSocket:sendAddFriendPdeng(self.ctx.model:selfSeatId(), self.data_.seatId)
                    else
                        nk.socket.RoomSocket:sendAddFriend(self.ctx.model:selfSeatId(), self.data_.seatId)
                    end
                    
                else
                    --不在座位，只播放动画，别人看不到
                    self.ctx.animManager:playAddFriendAnimation(-1, self.data_.seatId)
                end
                if retData.ret == 2 then
                    local noticed = nk.userDefault:getBoolForKey(nk.cookieKeys.FRIENDS_FULL_TIPS .. nk.userData.uid, false)
                    if not noticed then
                        nk.TopTipManager:showTopTip(bm.LangUtil.getText("FRIEND", "ADD_FULL_TIPS",nk.OnOff:getConfig("maxFriendNum") or "300"))
                        nk.userDefault:setBoolForKey(nk.cookieKeys.FRIENDS_FULL_TIPS .. nk.userData.uid, true)
                    end
                end
                self:hide()
            else
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "ADD_FRIEND_FAILED_MSG"))
                self:setAddFriendStatus()
            end
        end
    end, function()
        nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "ADD_FRIEND_FAILED_MSG"))
        self:setAddFriendStatus()
    end)
    
end

function UserInfoOtherDialog:onDelFriendClicked_(evt)
    self.addFriendBtn_:setButtonEnabled(false)
    bm.HttpService.POST({mod="friend", act="delPoker", fuid=self.data_.uid}, function(data)
        if data == "1" then
            self.isFriend_ = 0
        else
            nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "DEL_FRIEND_FAILED_MSG"))
        end
        
        self:setAddFriendStatus()
    end, function()
        nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "DEL_FRIEND_FAILED_MSG"))
        self:setAddFriendStatus()
    end)
end

function UserInfoOtherDialog:sendChipClicked_(chips)
    local roomType = self.ctx.model:roomType()
    if roomType == consts.ROOM_TYPE.NORMAL or roomType == consts.ROOM_TYPE.PRO or roomType == consts.ROOM_TYPE.TYPE_4K or roomType == consts.ROOM_TYPE.TYPE_5K then
        if self.ctx.model:isSelfInSeat() then
            nk.socket.RoomSocket:sendSendChips(self.ctx.model:selfSeatId(), self.data_.seatId, self.data_.uid, chips)
            self:hide()
        else
            nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "SEND_CHIP_NOT_IN_SEAT"))
        end
    else
        nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "SEND_CHIP_NOT_NORMAL_ROOM_MSG"))
    end
end

function UserInfoOtherDialog:sendHddjClicked_(hddjId)
    if self.isShowChip_ then
        nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "NOT_USE_HDDJ_MSG"))
        return
    end

    local roomType = self.ctx.model:roomType()
    if self.ctx.model:roomType() == consts.ROOM_TYPE.TOURNAMENT  then
        --比赛场不能发送互动道具
        nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "SEND_HDDJ_IN_MATCH_ROOM_MSG"))
    else
        if self.ctx.model:isSelfInSeat() then
            self.sendHddjId_ = hddjId
            if hddjId > 1000 then
                self:doSendWaterLampActHddj()
            elseif hddjId > 200 then
                self:doSendActHddj()            
            else
                if hddjId == 17 then
                    --todo
                    self:doSendPumpActHddj()
                else
                    if nk.userData.hddjNum then
                        self:doSendHddj()
                    else
                        self.hddjNumObserverId_ = bm.DataProxy:addPropertyObserver(nk.dataKeys.USER_DATA, "hddjNum", handler(self, self.doSendHddj))
                        bm.EventCenter:dispatchEvent(nk.eventNames.ROOM_LOAD_HDDJ_NUM)
                    end
                end
            end
        else
            --不在座位不能发送互动道具
            nk.TopTipManager:showTopTip(bm.LangUtil.getText("ROOM", "SEND_HDDJ_NOT_IN_SEAT"))
        end
    end
end

--发送节日互动道具
function UserInfoOtherDialog:doSendActHddj()
    bm.HttpService.POST({
            mod="Songkran",
            act="useActFunFace",
            hddjId = self.sendHddjId_,
            selfSeatId = self.ctx.model:selfSeatId(),
            receiverSeatId = self.data_.seatId
        },
        function(data)
            local jsonData = json.decode(data)
            local ret = jsonData.ret
            if ret == 0 then
                self.ctx.animManager:setAnimCompleteCallback(nil)
                self:sendHddj_()
            elseif ret == -2 then-- 道具数量不够
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("SONGKRAN", "NOT_ENOUGH_PROP"))
            elseif ret == -3 then-- 使用道具失败
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("SONGKRAN", "USE_PROP_FAIL"))
            end
        end,
        function()
        end)
end

--发送水灯节节日互动道具
function UserInfoOtherDialog:doSendWaterLampActHddj()
    bm.HttpService.POST({
            mod="Lkf",
            act="useProps",
            uid = tonumber(nk.userData.uid),
            selfSeatId = self.ctx.model:selfSeatId(),
            receiverSeatId = self.data_.seatId,
            propId = self.sendHddjId_,
        },
        function(data)       
            local jsonData = json.decode(data)
            local ret = jsonData.ret
            if ret == 0 then
                self:sendHddj_()
            else
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("SONGKRAN", "NOT_ENOUGH_PROP"))
            end
        end,
        function(code, msg)
        end)
end

function UserInfoOtherDialog:doSendPumpActHddj()
    -- body
    bm.HttpService.POST({mod = "Halloween", act = "usePumpkin", hddjId = self.sendHddjId_, selfSeatId = self.ctx.model:selfSeatId(), receiverSeatId = self.data_.seatId}, function(retData)
        local actData = json.decode(retData)
        -- dump(actData, "UserInfoOtherDialog:doSendPumpActHddj[Halloween.usePumpkin].actData :==============")

        if actData then
            --todo
            local dataCode = actData.code

            if dataCode == 1 then
                --todo
                math.randomseed(tostring(os.time()):reverse():sub(1, 6))

                self.ctx.animManager:setAnimCompleteCallback(function()
                    -- body
                    local utters = bm.LangUtil.getText("HALLOWEEN", "NAUGHTY_UTTERS")
                    local utterRandom = utters[math.random(1, 3)]
                    nk.socket.RoomSocket:sendChatMsg(utterRandom)
                end)

                self:sendHddj_()
            elseif dataCode == - 1 then
                --todo
                nk.ui.Dialog.new({messageText = bm.LangUtil.getText("HALLOWEEN", "NOT_ENOUGH_PROP"), secondBtnText = bm.LangUtil.getText("COMMON", "CONFIRM"), 
                    closeWhenTouchModel = false, hasFirstButton = false, hasCloseButton = false, callback = function(type)
                        if type == nk.ui.Dialog.SECOND_BTN_CLICK then
                        end
                end}
            ):show()
            else
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("SONGKRAN", "USE_PROP_FAIL"))
            end
        else
            nk.TopTipManager:showTopTip(bm.LangUtil.getText("SONGKRAN", "USE_PROP_FAIL"))
        end
    end, function(errData)
        dump(errData, "UserInfoOtherDialog:doSendPumpActHddj[Halloween.usePumpkin].errData :===============")
    end)
end

function UserInfoOtherDialog:doSendHddj()
    if nk.userData.hddjNum then
        if self.hddjNumObserverId_ then
            bm.DataProxy:removePropertyObserver(nk.dataKeys.USER_DATA, "hddjNum", self.hddjNumObserverId_)
            self.hddjNumObserverId_ = nil
        end

        if nk.userData.hddjNum > 0 then
            self:sendHddjAndHide_()
        else
            bm.HttpService.POST({mod="user", act="getUserFun"}, function(ret)
                local num = tonumber(ret)
                if num then
                    nk.userData.hddjNum = num
                    if num > 0 then
                        self:sendHddjAndHide_()
                    else
                        self:showHddjNotEnoughDialog_()
                    end
                end
            end,
            function()
            end)
        end
    end
end

function UserInfoOtherDialog:sendHddjAndHide_(isNorProp)
    nk.userData.hddjNum = nk.userData.hddjNum - 1
    
    bm.HttpService.POST({
            mod="user",
            act="useUserFun",
            hddjId=self.sendHddjId_,
            selfSeatId=self.ctx.model:selfSeatId(),
            receiverSeatId=self.data_.seatId
        },
        function(ret)
            --返回2成功
            print("use hddj ret -> ".. ret)
        end, function()
            print("use hddj fail")
        end)

    self.ctx.animManager:setAnimCompleteCallback(nil)

    self:sendHddj_()
end

function UserInfoOtherDialog:sendHddj_()
    -- local curScene = display.getRunningScene()
    -- if curScene and curScene.name == "MatchRoomScene" then
    --     -- nk.socket.MatchSocket:sendSendHddj(self.ctx.model:selfSeatId(), self.data_.seatId, self.sendHddjId_)
    -- -- else
    -- --    nk.socket.HallSocket:sendSendHddj(self.ctx.model:selfSeatId(), self.data_.seatId, self.sendHddjId_) 
    -- end

    self.ctx.animManager:playHddjAnimation(self.ctx.model:selfSeatId(), self.data_.seatId, self.sendHddjId_)

    self:hide()
end

function UserInfoOtherDialog:showHddjNotEnoughDialog_()
    nk.ui.Dialog.new({
        messageText = bm.LangUtil.getText("ROOM", "SEND_HDDJ_NOT_ENOUGH"), 
        firstBtnText = bm.LangUtil.getText("COMMON", "CANCEL"),
        secondBtnText = bm.LangUtil.getText("COMMON", "BUY"), 
        callback = function (type)
            if type == nk.ui.Dialog.SECOND_BTN_CLICK then
                self:hide()
                StorePopup.new(2):showPanel()
            end
        end
    }):show()
end

function UserInfoOtherDialog:updateKickData()
    bm.HttpService.POST({mod="user", act="getUserProps"},
        function(data)
            local callData = json.decode(data)
            if callData and #callData > 0 then
                for i = 1, #callData do
                    if callData[i].a == "5" then
                        nk.userData.kickNum = tonumber(callData[i].b)
                    end
                end
                self:updateKickButton()
            else
            end
        end, function()
        end)
end

function UserInfoOtherDialog:updateKickButton()
    local curScene = display.getRunningScene()
    if curScene and curScene.name == "MatchRoomScene" then
        self.kickBtn_:setButtonEnabled(false)
        return
    end
    if nk.userData.kickNum and nk.userData.kickNum > 0 then
        self.kickBtn_:setButtonImage("normal", {"#pop_userinfo_other_blue_normal.png", "#pop_userinfo_other_kickCard.png"})
        self.kickBtn_:setButtonImage("pressed", {"#pop_userinfo_other_blue_pressed.png", "#pop_userinfo_other_kickCard.png"})
    else
        self.kickBtn_:setButtonImage("normal", {"#pop_userinfo_other_blue_normal.png", "#pop_userinfo_other_kickCard_add.png"})
        self.kickBtn_:setButtonImage("pressed", {"#pop_userinfo_other_blue_pressed.png", "#pop_userinfo_other_kickCard_add.png"})
    end
end

function UserInfoOtherDialog:sendKickAndHide_()
    local curScene = display.getRunningScene()
    if curScene and curScene.name == "MatchRoomScene" then
        return
    end
    if nk.userData.kickNum and nk.userData.kickNum > 0 then
        bm.HttpService.POST({mod="user", act="kick", uid=nk.userData.uid, touid=self.data_.uid},
            function(data)
                local retData = json.decode(data)
                if retData and retData.ret == 0 then
                    nk.userData.kickNum = nk.userData.kickNum - 1
                    nk.TopTipManager:showTopTip(bm.LangUtil.getText("VIP", "KICK_SUCC"))
                    -- self:updateKickButton()
                elseif retData.ret == -2 then
                    -- self:updateKickData()
                    nk.TopTipManager:showTopTip(bm.LangUtil.getText("VIP", "KICK_FAILED"))
                elseif retData.ret == -4 then
                    nk.TopTipManager:showTopTip(bm.LangUtil.getText("VIP", "KICKER_TOO_MUCH"))
                else
                    nk.TopTipManager:showTopTip(bm.LangUtil.getText("VIP", "KICK_FAILED"))
                end
            end, function()
                nk.TopTipManager:showTopTip(bm.LangUtil.getText("VIP", "KICK_FAILED"))
            end)
    else
        StorePopup.new(2):showPanel()
    end
    
    self:hide()
end

function UserInfoOtherDialog:onHeadImgContainerClick_(target, evt)    
    if evt == bm.TouchHelper.CLICK then
        nk.SoundManager:playSound(nk.SoundManager.CLICK_BUTTON);
        UserAvatarPopup.new():show(self.data_);
    end
end

function UserInfoOtherDialog:onExit()
    if self.rankingRequestId_ then
        bm.HttpService.CANCEL(self.rankingRequestId_)
        self.rankingRequestId_ = nil
    end
    if self.hddjNumObserverId_ then
        bm.DataProxy:removePropertyObserver(nk.dataKeys.USER_DATA, "hddjNum", self.hddjNumObserverId_)
        self.hddjNumObserverId_ = nil
    end
    nk.ImageLoader:cancelJobByLoaderId(self.headImageLoaderId_)
end

return UserInfoOtherDialog
