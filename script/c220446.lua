-- Divine Arsenal D-6
local s, id, o = GetID()

function s.initial_effect(c)
	-- Chỉ cho phép 1 lá bài này trên sân.
	c:SetUniqueOnField(1, 0, id)

	-- Triệu hồi XYZ: Sử dụng 1+ quái thú Level 12.
	aux.AddXyzProcedure(c, nil, 12, 1, nil, nil, 99)
	c:EnableReviveLimit()

	-- Không thể bị flip face-down
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_CHANGE_POS_E)
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

	-- Hiệu ứng 2: Phủ nhận kích hoạt hiệu ứng hoặc triệu hồi quái thú của đối thủ.
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_F)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + o * 2)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
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

-- Điều kiện kích hoạt hiệu ứng phủ nhận: Chỉ từ đối thủ và là kích hoạt hiệu ứng hoặc triệu hồi quái thú.
function s.discon(e, tp, eg, ep, ev, re, r, rp)
	return ep ~= tp and (re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_MONSTER))
		and re:GetHandler() ~= e:GetHandler()
end

-- Mục tiêu của hiệu ứng phủ nhận.
function s.distg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
end

-- Hành động của hiệu ứng phủ nhận.
function s.disop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetCurrentChain() == ev + 1 then
		Duel.NegateActivation(ev)
	end
end

-- Giới hạn triệu hồi đặc biệt: Chỉ quái thú tộc Máy.
function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsRace(RACE_MACHINE)
end