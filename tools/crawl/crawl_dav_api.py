#!/usr/bin/env python3
"""
Tool crawl data từ DAV API và lưu vào file JSON
"""

import requests
import json
import os
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import time


class DavApiCrawler:
    def __init__(self, output_dir: str = "data", api_base_url: Optional[str] = None, api_token: Optional[str] = None):
        self.base_url = "https://dichvucong.dav.gov.vn/api/services/app/soDangKy/GetAllPublicServerPaging"
        self.output_dir = output_dir
        self.session = requests.Session()
        self.api_base_url = api_base_url  # URL của MedIntel API
        self.api_token = api_token  # JWT token nếu cần authentication
        
        # Headers từ curl command
        self.headers = {
            'accept': 'application/json, text/javascript, */*; q=0.01',
            'accept-language': 'en-US,en;q=0.9',
            'cache-control': 'no-cache',
            'content-type': 'application/json',
            'origin': 'https://dichvucong.dav.gov.vn',
            'pragma': 'no-cache',
            'referer': 'https://dichvucong.dav.gov.vn/congbothuoc/index',
            'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0',
            'x-requested-with': 'XMLHttpRequest',
        }
        
        # Cookies (có thể cần update khi hết hạn)
        self.cookies = {
            'Abp.Localization.CultureName': 'en',
            'ASP.NET_SessionId': 'mfikjju5ndeny2l4jkzv1uzw',
            '__RequestVerificationToken': 'R_Or5YAI7SD3eqtIzpGFcBM2O2SkMn86eJs6ZJlr_zaIVdcBMgSmrymhA0EFQUX0EYDGjqbtgUTqLLm9ILfiJhCiVew1',
            'SRV': '973c7d89-221c-43ab-aed6-6e180f2eb0b7',
            'XSRF-TOKEN': '9x30CrIC9LhHTa8EMmXaHb2Uc-sLUVPz9E0SDYutgnNd84dAwkItjDO2cB4ucc1pFT6A6fosj9oN7Ah4hWBrTfN3La81'
        }
        
        # Tạo thư mục output nếu chưa có
        os.makedirs(self.output_dir, exist_ok=True)
    
    def fetch_page(self, skip_count: int = 0, max_result_count: int = 10, 
                   filter_text: Optional[str] = None) -> Dict:
        """
        Fetch một trang dữ liệu từ API
        
        Args:
            skip_count: Số bản ghi bỏ qua (pagination)
            max_result_count: Số bản ghi tối đa trả về
            filter_text: Text để filter (optional)
        
        Returns:
            Dict chứa response từ API
        """
        payload = {
            "SoDangKyThuoc": {},
            "KichHoat": True,
            "skipCount": skip_count,
            "maxResultCount": max_result_count,
            "sorting": None
        }
        
        if filter_text:
            payload["filterText"] = filter_text
        
        # XSRF Token từ cookies
        xsrf_token = self.cookies.get('XSRF-TOKEN', '')
        if xsrf_token:
            self.headers['x-xsrf-token'] = xsrf_token
        
        try:
            response = self.session.post(
                self.base_url,
                headers=self.headers,
                cookies=self.cookies,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching page {skip_count}: {e}")
            return None
    
    def crawl_all(self, max_pages: Optional[int] = None, 
                  items_per_page: int = 1000, delay: float = 1.0) -> List[Dict]:
        """
        Crawl tất cả dữ liệu từ API
        
        Args:
            max_pages: Số trang tối đa để crawl (None = crawl tất cả)
            items_per_page: Số items mỗi trang
            delay: Thời gian delay giữa các request (giây)
        
        Returns:
            List chứa tất cả items
        """
        all_items = []
        skip_count = 0
        page = 1
        total_count = None
        
        print("Bắt đầu crawl dữ liệu từ DAV API...")
        
        while True:
            if max_pages and page > max_pages:
                break
            
            print(f"Đang crawl trang {page} (skip: {skip_count})...")
            
            response = self.fetch_page(skip_count, items_per_page)
            
            if not response or not response.get('success'):
                print(f"Lỗi khi crawl trang {page}")
                break
            
            result = response.get('result', {})
            items = result.get('items', [])
            
            if total_count is None:
                total_count = result.get('totalCount', 0)
                print(f"Tổng số bản ghi: {total_count}")
            
            if not items:
                print("Không còn dữ liệu để crawl")
                break
            
            all_items.extend(items)
            print(f"Đã crawl {len(items)} items (Tổng: {len(all_items)}/{total_count})")
            
            # Kiểm tra xem đã crawl hết chưa
            if len(all_items) >= total_count:
                print("Đã crawl hết tất cả dữ liệu")
                break
            
            skip_count += items_per_page
            page += 1
            
            # Delay để tránh rate limit
            if delay > 0:
                time.sleep(delay)
        
        print(f"\nHoàn thành! Tổng số items đã crawl: {len(all_items)}")
        return all_items
    
    def save_to_json(self, data: List[Dict], filename: Optional[str] = None):
        """
        Lưu data vào file JSON
        
        Args:
            data: List các items cần lưu
            filename: Tên file (None = tự động generate)
        """
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"dav_drugs_{timestamp}.json"
        
        filepath = os.path.join(self.output_dir, filename)
        
        output = {
            "metadata": {
                "total_count": len(data),
                "crawled_at": datetime.now().isoformat(),
                "source": "DAV API - https://dichvucong.dav.gov.vn"
            },
            "items": data
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(output, f, ensure_ascii=False, indent=2)
        
        print(f"\nĐã lưu {len(data)} items vào file: {filepath}")
        return filepath
    
    def parse_datetime(self, date_str: str) -> Optional[str]:
        """
        Parse datetime string từ DAV API format và convert sang format mà Java LocalDateTime có thể parse
        Java LocalDateTime không hỗ trợ timezone offset, nên ta cần convert về local time
        Format output: "2025-12-03T00:00:00" (không có timezone)
        """
        if not date_str:
            return None
        try:
            from datetime import datetime
            # DAV API format: "2025-12-03T00:00:00+07:00" hoặc "2025-12-03T00:00:00Z"
            # Parse với timezone
            if 'Z' in date_str:
                dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            else:
                dt = datetime.fromisoformat(date_str)
            
            # Convert về local time (bỏ timezone offset)
            # Trả về format ISO 8601 không có timezone: "YYYY-MM-DDTHH:MM:SS"
            return dt.strftime('%Y-%m-%dT%H:%M:%S')
        except Exception as e:
            print(f"  Warning: Cannot parse datetime '{date_str}': {e}")
            return None
    
    def parse_json_string(self, json_str: str) -> Optional[list]:
        """Parse JSON string từ DAV API"""
        if not json_str:
            return None
        try:
            return json.loads(json_str)
        except:
            return None
    
    def map_dav_item_to_drug_request(self, item: Dict) -> Dict:
        """
        Map dữ liệu từ DAV API sang format CreateDrugRequest (legacy)
        """
        drug_data = {
            "externalId": item.get("id"),
            "drugName": item.get("tenThuoc"),
            "registrationNumber": item.get("soDangKy"),
            "oldRegistrationNumber": item.get("soDangKyCu") or None,
            "drugCode": item.get("maThuoc") or None,
            "drugClassificationEnum": item.get("phanLoaiThuocEnum"),
            "isActive": item.get("isActive", True),
            "isExpired": item.get("isHetHan", False),
            "isAllowed": item.get("isDuocPhep", False),
            "notes": item.get("ghiChu") or None,
            "modificationReason": item.get("lyDoSuaDoi") or None,
            "status": item.get("trangThai") or None,
            "dataSourceEnum": item.get("nguonDuLieuEnum"),
            "rawData": item
        }
        
        basic_info = item.get("thongTinThuocCoBan", {})
        if basic_info:
            drug_data["drugTypeId"] = basic_info.get("loaiThuocId", 0) or None
            drug_data["drugGroupId"] = basic_info.get("nhomThuocId", 0) or None
        
        return drug_data
    
    def map_dav_item_to_import_full_request(self, item: Dict) -> Dict:
        """
        Map dữ liệu từ DAV API sang format ImportFullDrugRequest
        Bao gồm tất cả các bảng liên quan
        """
        # Thông tin cơ bản
        drug_data = {
            "externalId": item.get("id"),
            "drugName": item.get("tenThuoc"),
            "registrationNumber": item.get("soDangKy"),
            "oldRegistrationNumber": item.get("soDangKyCu") or None,
            "drugCode": item.get("maThuoc") or None,
            "drugClassificationEnum": item.get("phanLoaiThuocEnum"),
            "isActive": item.get("isActive", True),
            "isExpired": item.get("isHetHan", False),
            "isAllowed": item.get("isDuocPhep", False),
            "notes": item.get("ghiChu") or None,
            "modificationReason": item.get("lyDoSuaDoi") or None,
            "status": item.get("trangThai") or None,
            "dataSourceEnum": item.get("nguonDuLieuEnum"),
            "rawData": item
        }
        
        # Company information - chỉ thêm nếu có name
        cong_ty_sx = item.get("congTySanXuat", {})
        ten_cong_ty_sx = cong_ty_sx.get("tenCongTySanXuat") if cong_ty_sx else None
        if cong_ty_sx and ten_cong_ty_sx and ten_cong_ty_sx.strip():
            drug_data["manufacturerCompany"] = {
                "externalId": item.get("congTySanXuatId"),
                "name": ten_cong_ty_sx.strip(),
                "address": cong_ty_sx.get("diaChiSanXuat"),
                "country": cong_ty_sx.get("nuocSanXuat"),
                "countryId": cong_ty_sx.get("nuocSanXuatId")
            }
        
        cong_ty_dk = item.get("congTyDangKy", {})
        ten_cong_ty_dk = cong_ty_dk.get("tenCongTyDangKy") if cong_ty_dk else None
        if cong_ty_dk and ten_cong_ty_dk and ten_cong_ty_dk.strip():
            drug_data["registrantCompany"] = {
                "externalId": item.get("congTyDangKyId"),
                "name": ten_cong_ty_dk.strip(),
                "address": cong_ty_dk.get("diaChiDangKy"),
                "country": cong_ty_dk.get("nuocDangKy"),
                "countryId": cong_ty_dk.get("nuocDangKyId")
            }
        
        # Thông tin đăng ký
        thong_tin_dk = item.get("thongTinDangKyThuoc", {})
        if thong_tin_dk:
            drug_data["registrationInfo"] = {
                "registrationDate": self.parse_datetime(thong_tin_dk.get("ngayCapSoDangKy")),
                "extensionDate": self.parse_datetime(thong_tin_dk.get("ngayGiaHanSoDangKy")),
                "expiryDate": self.parse_datetime(thong_tin_dk.get("ngayHetHanSoDangKy")),
                "decisionNumber": thong_tin_dk.get("soQuyetDinh"),
                "decisionUrl": thong_tin_dk.get("urlSoQuyetDinh"),
                "batchNumber": thong_tin_dk.get("dotCap"),
                "isNhhsdkUpdated": thong_tin_dk.get("isCapNhatNHHSDK"),
                "withdrawalDocumentUrl": item.get("thongTinRutSoDangKy", {}).get("urlCongVanRutSoDangKy")
            }
        
        # Thông tin thuốc cơ bản
        thong_tin_co_ban = item.get("thongTinThuocCoBan", {})
        if thong_tin_co_ban:
            drug_data["basicInfo"] = {
                "activeIngredient": thong_tin_co_ban.get("hoatChatChinh"),
                "activeIngredientId": thong_tin_co_ban.get("hoatChatChinhId"),
                "activeIngredientConcentration": thong_tin_co_ban.get("hoatChatHamLuong"),
                "dosage": thong_tin_co_ban.get("hamLuong"),
                "dosageForm": thong_tin_co_ban.get("dangBaoChe"),
                "dosageFormId": thong_tin_co_ban.get("dangBaoCheId"),
                "packaging": thong_tin_co_ban.get("dongGoi"),
                "packagingJson": self.parse_json_string(thong_tin_co_ban.get("dongGoiJson")),
                "standard": thong_tin_co_ban.get("tieuChuan"),
                "standardId": thong_tin_co_ban.get("tieuChuanId"),
                "shelfLife": thong_tin_co_ban.get("tuoiTho"),
                "drugType": thong_tin_co_ban.get("loaiThuoc"),
                "drugTypeId": thong_tin_co_ban.get("loaiThuocId") if thong_tin_co_ban.get("loaiThuocId") else None,
                "drugGroup": thong_tin_co_ban.get("nhomThuoc"),
                "drugGroupId": thong_tin_co_ban.get("nhomThuocId") if thong_tin_co_ban.get("nhomThuocId") else None,
                "administrationRouteCode": thong_tin_co_ban.get("maDuongDung"),
                "administrationRouteName": thong_tin_co_ban.get("tenDuongDung")
            }
        
        # Tài liệu
        thong_tin_tl = item.get("thongTinTaiLieu", {})
        documents = []
        
        # Parse HDSD
        url_hdsd = self.parse_json_string(thong_tin_tl.get("urlHuongDanSuDung"))
        if url_hdsd:
            for doc in url_hdsd:
                documents.append({
                    "documentType": "HDSD",
                    "filePath": doc.get("duongDanTep"),
                    "fileDescription": doc.get("moTaTep"),
                    "attachmentJson": doc,
                    "isLabelPublished": doc.get("isCongBoMauNhan", False),
                    "isUsageGuidePublished": doc.get("isCongBoHdsd", False),
                    "isQualityStandardPublished": doc.get("isCongBoTccl", False)
                })
        
        # Parse Label
        url_nhan = self.parse_json_string(thong_tin_tl.get("urlNhan"))
        if url_nhan:
            for doc in url_nhan:
                documents.append({
                    "documentType": "LABEL",
                    "filePath": doc.get("duongDanTep"),
                    "fileDescription": doc.get("moTaTep"),
                    "attachmentJson": doc,
                    "isLabelPublished": doc.get("isCongBoMauNhan", False),
                    "isUsageGuidePublished": doc.get("isCongBoHdsd", False),
                    "isQualityStandardPublished": doc.get("isCongBoTccl", False)
                })
        
        # Parse TCCL
        json_tccl = self.parse_json_string(thong_tin_tl.get("jsonTaiLieuTCCL"))
        if json_tccl:
            for doc in json_tccl:
                documents.append({
                    "documentType": "TCCL",
                    "filePath": doc.get("duongDanTep"),
                    "fileDescription": doc.get("moTaTep"),
                    "attachmentJson": doc,
                    "isLabelPublished": doc.get("isCongBoMauNhan", False),
                    "isUsageGuidePublished": doc.get("isCongBoHdsd", False),
                    "isQualityStandardPublished": doc.get("isCongBoTccl", False)
                })
        
        if documents:
            drug_data["documents"] = documents
        
        # Thuốc kiểm soát đặc biệt
        thuoc_ksdb = item.get("thuocKiemSoatDacBiet", {})
        if thuoc_ksdb and any([thuoc_ksdb.get("isHoSoACTD"), thuoc_ksdb.get("isHoSoLamSang"),
                              thuoc_ksdb.get("nguoiLap"), thuoc_ksdb.get("chuTichHoiDong")]):
            drug_data["specialControl"] = {
                "isActdFile": thuoc_ksdb.get("isHoSoACTD"),
                "isClinicalFile": thuoc_ksdb.get("isHoSoLamSang"),
                "preparer": thuoc_ksdb.get("nguoiLap"),
                "councilChairman": thuoc_ksdb.get("chuTichHoiDong"),
                "councilSecretary": thuoc_ksdb.get("thuKyHoiDong"),
                "approver": thuoc_ksdb.get("nguoiDuyet"),
                "decisionDate": self.parse_datetime(thuoc_ksdb.get("ngayQuyetDinhCongVan")),
                "decisionNumber": thuoc_ksdb.get("soQuyetDinhCongVan") or thuoc_ksdb.get("soQuyetDinhCongVan")
            }
        
        # Vaccine/Sinh phẩm
        vac_xin = item.get("vacXinSinhPham", {})
        if vac_xin and (vac_xin.get("loaiVacXin") or vac_xin.get("phongBenh")):
            drug_data["vaccineInfo"] = {
                "vaccineType": vac_xin.get("loaiVacXin") if vac_xin.get("loaiVacXin") else None,
                "diseasePrevention": vac_xin.get("phongBenh")
            }
        
        return drug_data
    
    def upload_to_api(self, drug_data: Dict, use_full_import: bool = False) -> Tuple[Optional[bool], Optional[str]]:
        """
        Upload drug data lên MedIntel API
        
        Args:
            drug_data: Drug data theo format CreateDrugRequest hoặc ImportFullDrugRequest
            use_full_import: Nếu True, sử dụng endpoint import-full
            
        Returns:
            Tuple (result, error_message):
            - (True, None): Thành công
            - (None, None): Đã tồn tại (skip)
            - (False, error_message): Lỗi (kèm error message)
        """
        if not self.api_base_url:
            return (False, "API base URL not configured")
        
        url = f"{self.api_base_url}/api/drugs/import-full" if use_full_import else f"{self.api_base_url}/api/drugs"
        headers = {
            "Content-Type": "application/json"
        }
        
        if self.api_token:
            headers["Authorization"] = f"Bearer {self.api_token}"
        
        try:
            response = self.session.post(url, json=drug_data, headers=headers, timeout=30)
            if response.status_code in [200, 201]:
                return (True, None)
            elif response.status_code in [400, 409, 500]:
                # Check if it's a duplicate error (có thể là 400, 409, hoặc 500)
                error_text = response.text.lower()
                if "already exists" in error_text or "duplicate" in error_text:
                    # Parse error message để biết lý do skip (external_id hay registration_number)
                    skip_reason = "đã tồn tại"
                    if "external id" in error_text:
                        skip_reason = "external_id đã tồn tại"
                    elif "registration number" in error_text:
                        skip_reason = "registration_number đã tồn tại"
                    return (None, skip_reason)  # Already exists - skip
                # Lỗi khác
                error_msg = response.text[:300] if len(response.text) > 300 else response.text
                return (False, f"{response.status_code}: {error_msg}")
            else:
                error_msg = response.text[:300] if len(response.text) > 300 else response.text
                return (False, f"{response.status_code}: {error_msg}")
        except requests.exceptions.RequestException as e:
            return (False, str(e))
    
    def crawl_and_upload(self, max_pages: Optional[int] = None,
                        items_per_page: int = 1000, delay: float = 0.5,
                        skip_existing: bool = True, use_full_import: bool = True):
        """
        Crawl và upload trực tiếp lên API
        
        Args:
            max_pages: Số trang tối đa (None = tất cả)
            items_per_page: Số items mỗi trang
            delay: Delay giữa các request
            skip_existing: Bỏ qua nếu đã tồn tại (dựa trên external_id)
            use_full_import: Sử dụng API import-full để insert đầy đủ các bảng liên quan
        """
        all_items = []
        skip_count = 0
        page = 1
        total_count = None
        uploaded_count = 0
        skipped_count = 0
        error_count = 0
        
        print("Bắt đầu crawl và upload dữ liệu lên API...")
        if use_full_import:
            print("Sử dụng API import-full (insert đầy đủ các bảng liên quan)")
        
        while True:
            if max_pages and page > max_pages:
                break
            
            print(f"\nĐang crawl trang {page} (skip: {skip_count})...")
            
            response = self.fetch_page(skip_count, items_per_page)
            
            if not response or not response.get('success'):
                print(f"Lỗi khi crawl trang {page}")
                break
            
            result = response.get('result', {})
            items = result.get('items', [])
            
            if total_count is None:
                total_count = result.get('totalCount', 0)
                print(f"Tổng số bản ghi: {total_count}")
            
            if not items:
                print("Không còn dữ liệu để crawl")
                break
            
            # Upload từng item
            for idx, item in enumerate(items, 1):
                try:
                    if use_full_import:
                        drug_data = self.map_dav_item_to_import_full_request(item)
                    else:
                        drug_data = self.map_dav_item_to_drug_request(item)
                    
                    result, error_msg = self.upload_to_api(drug_data, use_full_import=use_full_import)
                    external_id = item.get("id", "unknown")
                    drug_name = item.get("tenThuoc", "unknown")
                    registration_number = item.get("soDangKy", "N/A")
                    
                    if result:
                        uploaded_count += 1
                        # Không log khi upload thành công - chỉ log skip/error
                    elif result is None:
                        # Already exists - skip
                        skipped_count += 1
                        skip_reason = error_msg if error_msg else "đã tồn tại"
                        print(f"  ⚠️  Skip: external_id={external_id}, reg_num='{registration_number}', name='{drug_name}' ({skip_reason})")
                    else:
                        # Error
                        error_count += 1
                        print(f"  ❌ Error: external_id={external_id}, reg_num='{registration_number}', name='{drug_name}' - {error_msg}")
                except Exception as e:
                    error_count += 1
                    external_id = item.get("id", "unknown")
                    drug_name = item.get("tenThuoc", "unknown")
                    registration_number = item.get("soDangKy", "N/A")
                    print(f"  ❌ Exception: external_id={external_id}, reg_num='{registration_number}', name='{drug_name}' - {e}")
            
            all_items.extend(items)
            # Chỉ hiển thị summary nếu có skip hoặc error
            if skipped_count > 0 or error_count > 0:
                print(f"Trang {page}: ✅ {uploaded_count} | ⚠️  {skipped_count} | ❌ {error_count} (Tổng: {len(all_items)}/{total_count})")
            else:
                print(f"Trang {page}: ✅ {uploaded_count} items (Tổng: {len(all_items)}/{total_count})")
            
            # Kiểm tra xem đã crawl hết chưa
            if len(all_items) >= total_count:
                print("Đã crawl hết tất cả dữ liệu")
                break
            
            skip_count += items_per_page
            page += 1
            
            # Delay để tránh rate limit
            if delay > 0:
                time.sleep(delay)
        
        print(f"\n=== Hoàn thành ===")
        print(f"Tổng items đã crawl: {len(all_items)}")
        print(f"✅ Upload thành công: {uploaded_count}")
        if skipped_count > 0:
            print(f"⚠️  Đã tồn tại (skip): {skipped_count}")
        if error_count > 0:
            print(f"❌ Lỗi: {error_count}")
    
    def crawl_and_save(self, max_pages: Optional[int] = None, 
                       items_per_page: int = 1000, delay: float = 1.0,
                       filename: Optional[str] = None):
        """
        Crawl và lưu dữ liệu
        
        Args:
            max_pages: Số trang tối đa (None = tất cả)
            items_per_page: Số items mỗi trang
            delay: Delay giữa các request
            filename: Tên file output
        """
        items = self.crawl_all(max_pages, items_per_page, delay)
        if items:
            return self.save_to_json(items, filename)
        return None


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Crawl data từ DAV API')
    parser.add_argument('--max-pages', type=int, default=None,
                       help='Số trang tối đa để crawl (mặc định: tất cả)')
    parser.add_argument('--items-per-page', type=int, default=1000,
                       help='Số items mỗi trang (mặc định: 1000)')
    parser.add_argument('--delay', type=float, default=0.5,
                       help='Delay giữa các request (giây, mặc định: 0.5)')
    parser.add_argument('--output-dir', type=str, default='data',
                       help='Thư mục lưu file output (mặc định: data)')
    parser.add_argument('--filename', type=str, default=None,
                       help='Tên file output (mặc định: tự động)')
    parser.add_argument('--test', action='store_true',
                       help='Test mode: chỉ crawl 1 trang')
    parser.add_argument('--upload', action='store_true',
                       help='Upload trực tiếp lên API thay vì lưu file')
    parser.add_argument('--api-url', type=str, default='http://localhost:8080',
                       help='URL của MedIntel API (mặc định: http://localhost:8080)')
    parser.add_argument('--api-token', type=str, default=None,
                       help='JWT token để authenticate (nếu cần)')
    parser.add_argument('--full-import', action='store_true', default=True,
                       help='Sử dụng API import-full để insert đầy đủ các bảng liên quan (mặc định: True)')
    
    args = parser.parse_args()
    
    crawler = DavApiCrawler(
        output_dir=args.output_dir,
        api_base_url=args.api_url if args.upload else None,
        api_token=args.api_token
    )
    
    if args.test:
        print("=== TEST MODE: Chỉ crawl 1 trang ===")
        if args.upload:
            crawler.crawl_and_upload(max_pages=1, items_per_page=10, delay=0.5, use_full_import=args.full_import)
        else:
            crawler.crawl_and_save(max_pages=1, items_per_page=10, delay=0.5, filename=args.filename)
    else:
        if args.upload:
            crawler.crawl_and_upload(
                max_pages=args.max_pages,
                items_per_page=args.items_per_page,
                delay=args.delay,
                use_full_import=args.full_import
            )
        else:
            crawler.crawl_and_save(
                max_pages=args.max_pages,
                items_per_page=args.items_per_page,
                delay=args.delay,
                filename=args.filename
            )


if __name__ == "__main__":
    main()

