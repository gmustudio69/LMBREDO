--Rikka Frostbud
local s,id=GetID()
function s.initial_effect(c)
	-- ===============================================
	-- Hiệu ứng 1: Tự nhảy từ tay nếu có Rikka
	-- ===============================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ===============================================
	-- Hiệu ứng 2: Bị Tribute hoặc Detach -> Gọi quái & Đổi Level
	-- ===============================================
	-- Bắt sự kiện bị Tribute
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.revtg)
	e2:SetOperation(s.revop)
	c:RegisterEffect(e2)
	
	-- Bắt sự kiện bị Detach (gửi xuống mộ làm cost cho Plant Xyz)
	local e3=e2:Clone()
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.detachcon)
	c:RegisterEffect(e3)
end
s.listed_series={0x141}
s.listed_names={id}

-- Logic Effect 1 (Nhảy từ tay)
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x141)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Logic Effect 2 & 3 (Hồi sinh và đổi level)
function s.detachcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_COST) and re and re:IsActivated() 
		and re:IsActiveType(TYPE_XYZ) and re:GetHandler():IsRace(RACE_PLANT)
end
function s.revfilter(c,e,tp)
	return c:IsRace(RACE_PLANT) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.revfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.revfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.revfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Cho phép người chơi chọn Level
		local lvl=Duel.AnnounceNumber(tp,4,6,8)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(lvl)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end