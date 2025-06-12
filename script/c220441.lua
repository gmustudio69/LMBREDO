-- Divine Arsenal Y-1
local s, id, o = GetID()

function s.initial_effect(c)
	-- Chỉ cho phép 1 lá bài này trên sân.
	c:SetUniqueOnField(1, 0, id)

	-- Triệu hồi XYZ: Sử dụng 1+ quái thú Level 12.
	aux.AddXyzProcedure(c, nil, 12, 1, nil, nil, 99)
	c:EnableReviveLimit()

	-- Không thể bị Tribute
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_UNRELEASABLE_SUM)
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

	-- Hiệu ứng 2: Trả quái thú triệu hồi của đối thủ về tay khi triệu hồi thành công.
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + o * 2)
	e2:SetCondition(s.rthcon)
	e2:SetTarget(s.rthtg)
	e2:SetOperation(s.rthop)
	c:RegisterEffect(e2)

	-- Hiệu ứng 3: Kích hoạt khi triệu hồi đặc biệt thành công (clone hiệu ứng 2).
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Hiệu ứng 4: Giới hạn triệu hồi đặc biệt (chỉ cho phép quái thú tộc Máy).
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

-- Điều kiện: Quái thú triệu hồi thuộc về đối thủ.
function s.rthcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(Card.IsControler, 1, nil, 1 - tp)
end

-- Mục tiêu: Trả quái thú đối thủ về tay.
function s.rthtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return eg:IsExists(Card.IsAbleToHand, 1, nil) end
	Duel.SetTargetCard(eg)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, eg, #eg, 0, 0)
end

-- Hành động: Trả quái thú đối thủ về tay.
function s.rthop(e, tp, eg, ep, ev, re, r, rp)
	local g = eg:Filter(Card.IsRelateToEffect, nil, e)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
	end
end

-- Giới hạn triệu hồi đặc biệt: Chỉ quái thú tộc Máy.
function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsRace(RACE_MACHINE)
end