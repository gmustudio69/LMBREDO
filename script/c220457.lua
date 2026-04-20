--<Limit Breaker> Shadow Catastrophe
local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Gửi 1 LIGHT Warrior -> Gọi 1 Warrior từ Mộ & Trang bị lá này
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Effect 2: Special Summon Token when sent to GY
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.tktg)
	e3:SetOperation(s.tkop)
	c:RegisterEffect(e3)
	-- Effect 3: Quái thú được trang bị nhận thêm hệ DARK
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_EQUIP)
	e4:SetCode(EFFECT_ADD_ATTRIBUTE)
	e4:SetValue(ATTRIBUTE_DARK)
	c:RegisterEffect(e4)
end

-- ==========================================
-- Xử lý Effect 1 (Send & Equip)
-- ==========================================
function s.tgfilter(c)
	return c:IsLevel(7) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR) and c:IsAbleToGrave()
end
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_WARRIOR) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	-- Phần Special Summon là "then you can" nên không bắt buộc phải có target từ trước lúc kích hoạt
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	-- Thực hiện bước gửi bài
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		-- Kiểm tra xem sân có chỗ và dưới Mộ có Warrior không
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		if not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) then return end
		
		-- Hỏi người chơi có muốn thực hiện vế "then you can special summon..." không
		if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
			local tc=sg:GetFirst()
			if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
				-- Trang bị lá bài này cho quái vừa gọi
				if c:IsRelateToEffect(e) and c:IsControler(tp) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
					Duel.Equip(tp,c,tc)
					-- Đảm bảo Equip Spell bị hủy nếu target biến mất
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_EQUIP_LIMIT)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					e1:SetValue(s.eqlimit)
					e1:SetLabelObject(tc)
					c:RegisterEffect(e1)
				end
			end
		end
	end
end
function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	and Duel.IsPlayerCanSpecialSummonMonster(tp,220422,0,TYPES_TOKEN,2000,2000,6,RACE_ILLUSION,ATTRIBUTE_DARK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
	end

 function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,220422,0,TYPES_TOKEN,2000,2000,6,RACE_ILLUSION,ATTRIBUTE_DARK) then return end

	local token=Duel.CreateToken(tp,220422)

	--make it tuner
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_TYPE)
	e1:SetValue(TYPE_TUNER)
	token:RegisterEffect(e1)

	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end