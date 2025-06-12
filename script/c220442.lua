-- Divine Arsenal B-2
local s, id, o = GetID()

function s.initial_effect(c)
	-- Chỉ cho phép 1 lá bài này trên sân.
	c:SetUniqueOnField(1, 0, id)

	-- Triệu hồi XYZ: Sử dụng 1+ quái thú Level 12.
	aux.AddXyzProcedure(c, nil, 12, 1, nil, nil, 99)
	c:EnableReviveLimit()

	-- không thể bị banish
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_REMOVE)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	-- Hiệu ứng 1: Triệu hồi đặc biệt từ Extra Deck.
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCountLimit(1, id + EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Hiệu ứng 2: Loại bỏ ngẫu nhiên 1 lá bài trên tay đối thủ khi có lá bài được thêm vào tay.
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + o * 2)
	e2:SetCondition(s.hdcon)
	e2:SetTarget(s.hdtg)
	e2:SetOperation(s.hdop)
	c:RegisterEffect(e2)

	-- Hiệu ứng 3: Giới hạn triệu hồi đặc biệt (chỉ cho phép quái thú tộc Máy).
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetRange(LOCATION_MZONE + LOCATION_GRAVE)
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetTargetRange(1, 0)
	e4:SetTarget(s.splimit)
	c:RegisterEffect(e4)
end

-- Điều kiện triệu hồi đặc biệt từ Extra Deck: Kiểm tra có lá bài ID 220448 trên sân.
function s.filter(c)
	return c:IsCode(220448) and c:IsFaceup()
end

function s.spcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_ONFIELD, 0, 1, nil)
end

-- Điều kiện: Khi có lá bài được thêm vào tay (không phải phase rút bài).
function s.cfilter(c,tp)
	return c:IsControler(tp) and c:IsPreviousLocation(LOCATION_DECK)
end
function s.hdcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()~=PHASE_DRAW and eg:IsExists(s.cfilter,1,nil,1-tp)
end

-- Mục tiêu: Loại bỏ 1 lá bài ngẫu nhiên trên tay đối thủ.
function s.hdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_HAND,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND)
end

-- Hành động: Loại bỏ 1 lá bài ngẫu nhiên trên tay đối thủ.
function s.hdop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_HAND,nil)
	if g:GetCount()>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
end

-- Giới hạn triệu hồi đặc biệt: Chỉ quái thú tộc Máy.
function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsRace(RACE_MACHINE)
end