--Rikka Princess of the White Frost
local s,id=GetID()
function s.initial_effect(c)
	-- ===============================================
	-- Hiệu ứng 1: Quick Effect - Gọi từ Tay/Mộ và Banish
	-- ===============================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ===============================================
	-- Hiệu ứng 2: Bị Tribute -> Lấy Rikka từ Mộ lên Tay
	-- ===============================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- ===============================================
	-- Global Check: Theo dõi hành động của Đối thủ
	-- ===============================================
	if not s.global_check then
		s.global_check=true
		-- Check đối thủ Special Summon
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop1)
		Duel.RegisterEffect(ge1,0)
		-- Check đối thủ kích hoạt effect từ Tay hoặc Mộ
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_CHAINING)
		ge2:SetOperation(s.checkop2)
		Duel.RegisterEffect(ge2,0)
	end
end
s.listed_series={0x141}

-- Logic Global Check
function s.checkop1(e,tp,eg,ep,ev,re,r,rp)
	local p1=false
	local p2=false
	for tc in aux.Next(eg) do
		if tc:IsControler(0) then p1=true end
		if tc:IsControler(1) then p2=true end
	end
	-- Gắn cờ cho người chơi nếu đối thủ của họ Special Summon
	if p1 then Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1) end
	if p2 then Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1) end
end
function s.checkop2(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_MONSTER) and (re:GetHandler():IsLocation(LOCATION_HAND) or re:GetHandler():IsLocation(LOCATION_GRAVE)) then
		Duel.RegisterFlagEffect(1-rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

-- ===============================================
-- Logic Effect 1 (Special Summon & Banish)
-- ===============================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	-- Chỉ dùng trong Main Phase VÀ khi đối thủ đã thỏa mãn điều kiện
	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2) and Duel.GetFlagEffect(tp,id)>0
end
function s.cfilter(c,tp)
	-- Lọc Plant trên tay hoặc ngửa trên sân (bao gồm cả quái đối thủ nếu có Konkon)
	return c:IsRace(RACE_PLANT) and (c:IsControler(tp) or c:IsFaceup())
end
function s.costchk(c,tp,b1)
	-- Kiểm tra xem sau khi hiến tế có còn ô trống để nhảy quái xuống không
	if c:IsLocation(LOCATION_MZONE) and c:GetSequence()<5 then
		return Duel.GetMZoneCount(tp,c)>0
	else
		return b1
	end
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Lấy danh sách quái có thể Tribute trên sân (Hỗ trợ Rikka Konkon)
	local rg=Duel.GetReleaseGroup(tp,true):Filter(s.cfilter,nil,tp)
	-- Lấy danh sách quái Plant có thể Tribute trên tay
	local hg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_HAND,0,nil):Filter(Card.IsRace,nil,RACE_PLANT)
	rg:Merge(hg)
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	
	if chk==0 then return rg:IsExists(s.costchk,1,c,tp,b1) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local sg=rg:FilterSelect(tp,s.costchk,1,1,c,tp,b1)
	Duel.Release(sg,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,LOCATION_ONFIELD+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Đặc triệu hồi
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Chọn và Trục xuất KHÔNG TARGET (Bypass hoàn toàn khả năng né đòn của meta)
		local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then -- Hiện thông báo "Bạn có muốn Banish không?"
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local sg=g:Select(tp,1,1,nil)
			Duel.HintSelection(sg)
			Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
		end
	end
end

-- ===============================================
-- Logic Effect 2 (Bị Tribute -> Lấy Rikka từ Mộ)
-- ===============================================
function s.thfilter(c)
	return c:IsSetCard(0x141) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end