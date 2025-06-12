-- Divine Arsenal AA-HADES - Death Bringer
local s, id = GetID()

function s.initial_effect(c)
	-- Chỉ cho phép 1 lá bài này trên sân.
	c:SetUniqueOnField(1, 0, id)

	-- Triệu hồi XYZ yêu cầu 6 quái Rank 12 làm nguyên liệu
	aux.AddXyzProcedure(c, nil, 12, 6, s.ovfilter, nil, nil, s.xyzop)
	c:EnableReviveLimit()

	-- Giới hạn triệu hồi đặc biệt (chỉ cho phép XYZ Summon)
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.xyzlimit)
	c:RegisterEffect(e0)

	-- Gain effect của tất cả XYZ Material
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.copy_condition)
	e1:SetOperation(s.copy_effect)
	c:RegisterEffect(e1)

	-- Reset hiệu ứng khi rời sân
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetOperation(s.reset_effect)
	c:RegisterEffect(e2)
end

-- Chỉ cho phép triệu hồi từ 6 quái Rank 12
function s.ovfilter(c, xyzc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:GetRank() == 12
end

-- Xử lý triệu hồi XYZ
function s.xyzop(e, tp, chk)
	if chk == 0 then 
		return Duel.IsExistingMatchingCard(s.ovfilter, tp, LOCATION_ONFIELD, 0, 1, nil) 
	end

	local c = e:GetHandler()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_XMATERIAL)
	local g = Duel.SelectMatchingCard(tp, s.ovfilter, tp, LOCATION_ONFIELD, 0, 1, 6, nil)

	if #g > 0 then
		Duel.Overlay(c, g)
	end
end


-- Điều kiện để copy effect (chỉ khi XYZ Summon)
function s.copy_condition(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

-- Copy toàn bộ effect của XYZ Material
function s.copy_effect(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local g = c:GetOverlayGroup():Filter(Card.IsType, nil, TYPE_XYZ)

	for tc in aux.Next(g) do
		-- Copy effect bằng cách thêm CODE của monster
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_CODE)
		e1:SetValue(tc:GetOriginalCodeRule())
		e1:SetReset(RESET_EVENT + RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- Copy effect chính của monster
		local code = tc:GetOriginalCode()
		local mt = _G["c" .. code]
		if mt and mt.initial_effect then
			mt.initial_effect(c)
		end
	end
end

-- Reset hiệu ứng khi rời sân
function s.reset_effect(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	c:ResetEffect(EFFECT_ADD_CODE, RESET_CODE)
end
